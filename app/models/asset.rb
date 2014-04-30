require 'virus_scanner'

class Asset
  include Mongoid::Document
  include Mongoid::Timestamps

  field :file, type: String
  field :state, type: String, default: 'unscanned'
  field :filename_history, type: Array
  protected :filename_history=

  field :access_limited, type: Boolean, default: false
  field :organisation_slug, type: String

  validates :file, presence: true
  validates :organisation_slug, presence: true, if: :access_limited?

  mount_uploader :file, AssetUploader

  before_save :reset_state_if_file_changed
  after_save :schedule_virus_scan

  state_machine :state, :initial => :unscanned do
    event :scanned_clean do
      transition any => :clean
    end

    event :scanned_infected do
      transition any => :infected
    end
  end

  def file=(file)
    super(file).tap {
      if file
        filename_history.push(File.basename(file.original_filename))
      end
    }
  end

  def filename_valid?(filename_to_test)
    valid_filenames.include?(filename_to_test)
  end

  def filename
    file.file.identifier
  end

  def scan_for_viruses
    scanner = VirusScanner.new(self.file.current_path)
    if scanner.clean?
      self.scanned_clean
    else
      ExceptionNotifier::Notifier.background_exception_notification VirusScanner::InfectedFile.new, :data => {:virus_info => scanner.virus_info}
      self.scanned_infected
    end
  rescue => e
    ExceptionNotifier::Notifier.background_exception_notification e
    raise
  end

  def accessible_by?(user)
    return true unless access_limited?

    user && user.organisation_slug == self.organisation_slug
  end

protected

  def filename_history
    super || self.filename_history = []
  end

  def valid_filenames
    filename_history + [filename]
  end

  def reset_state_if_file_changed
    if self.file_changed?
      self.state = 'unscanned'
    end
  end

  def schedule_virus_scan
    self.delay.scan_for_viruses if self.unscanned?
  end
end

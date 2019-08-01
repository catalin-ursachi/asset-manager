class WhitehallAssetsController < BaseAssetsController
  def create
    if existing_asset_with_this_legacy_url_path.exists?
      existing_asset_with_this_legacy_url_path.destroy
    end

    super
  end

private

  def asset_params
    base_asset_params.permit(:file,
                             :draft,
                             :redirect_url,
                             :replacement_id,
                             :legacy_url_path,
                             :legacy_etag,
                             :legacy_last_modified,
                             :parent_document_url,
                             access_limited_user_ids: [],
                             access_limited_organisation_ids: [])
  end

  def existing_asset_with_this_legacy_url_path
    WhitehallAsset.where(legacy_url_path: asset_params[:legacy_url_path])
  end

  def find_asset(include_deleted: false)
    scope = include_deleted ? WhitehallAsset : WhitehallAsset.undeleted
    scope.from_params(
      path: params[:path], format: params[:format]
    )
  end

  def build_asset
    WhitehallAsset.new(asset_params)
  end
end

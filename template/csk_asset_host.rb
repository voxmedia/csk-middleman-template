# fork of core AssetHost extension
# https://github.com/middleman/middleman/blob/v4.3.10/middleman-core/lib/middleman-core/extensions/asset_host.rb
require 'addressable/uri'

class CskAssetHost < ::Middleman::Extension
  option :host, nil, 'The asset host to use or a Proc to determine asset host', required: true
  option :exts, nil, 'List of extensions that get cache busters strings appended to them.'
  option :sources, %w(.css .htm .html .js .php .xhtml), 'List of extensions that are searched for bustable assets.'
  option :ignore, [], 'Regexes of filenames to skip adding query strings to'
  option :rewrite_ignore, [], 'Regexes of filenames to skip processing for host rewrites'
  option :asset_path_rewriter, nil, 'Proc for modifying the asset path'

  def initialize(app, options_hash={}, &block)
    super

    app.rewrite_inline_urls id: :asset_host,
                            url_extensions: options.exts || app.config[:asset_extensions],
                            source_extensions: options.sources,
                            ignore: options.ignore,
                            rewrite_ignore: options.rewrite_ignore,
                            proc: method(:rewrite_url)
  end

  Contract String, Or[String, Pathname], Any => String
  def rewrite_url(asset_path, dirpath, _request_path)
    uri = ::Middleman::Util.parse_uri(asset_path)
    relative_path = uri.path[0..0] != '/'

    full_asset_path = if relative_path
      dirpath.join(asset_path).to_s
    else
      asset_path
    end

    full_asset_path = sanitize_full_asset_path(full_asset_path)

    asset_prefix = if options[:host].is_a?(Proc)
      options[:host].call(full_asset_path)
    elsif options[:host].is_a?(String)
      options[:host]
    end

    File.join(asset_prefix, full_asset_path)
  end
  memoize :rewrite_url

  private
  def sanitize_full_asset_path full_asset_path
    parts = full_asset_path.split('/')
    path_prefix = parts[0...-1]
    filename = parts[-1]
    # Duplicate the sanitization done by the asset host (replace non-word characters with `_`)
    sanitized_filename = filename.gsub(/[^.\w]/, '_')

    (path_prefix + [sanitized_filename]).join('/')
  end
end

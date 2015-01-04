# The Driver class drives the application logic in the viddl-rb utility.
# It gets the correct plugin for the given url and passes a download queue
# (that it gets from the plugin) to the Downloader object which downloads the videos.
class Driver

  def initialize(param_hash)
    @params = param_hash
    @downloader = Downloader.new
  end

  #starts the downloading process or print just the urls or names.
  def start
    queue = get_download_queue

		# Gary
    if @params[:url_only]
      queue.each { |url_name| puts url_name[0][:url] }
    elsif @params[:title_only]
      queue.each { |url_name| puts url_name[0][:name] }
    else
      @downloader.download(queue, @params)
    end
  end

  private

  #finds the right plugins and returns the download queue.
  def get_download_queue
		return_plugins = Array.new	
    urls = @params[:urls]
		plugins = Array.new

		urls.each { |url| 
			plugins.push(
				ViddlRb::PluginBase.registered_plugins.find { |p| p.matches_provider?(url) } 
			)	 
		}

    #plugin = ViddlRb::PluginBase.registered_plugins.find { |p| p.matches_provider?(url) }
    raise "ERROR: No plugin seems to feel responsible for this URL." unless plugins
    puts "Using plugin: #{plugins}"

    begin
      #we'll end up with an array of hashes with they keys :url and :name
			# http://stackoverflow.com/questions/10165469/looping-through-the-index-of-an-array
			plugins.each_with_index do  |plugin, key|
				urls_and_filenames = plugin.get_urls_and_filenames(urls[key], @params)
      	return_plugins.push( urls_and_filenames )
			end      
	
			return_plugins
    rescue ViddlRb::PluginBase::CouldNotDownloadVideoError => e
      raise "CouldNotDownloadVideoError.\n" +
            "Reason: #{e.message}"
    rescue StandardError => e
      raise "Error while running the #{plugin.name.inspect} plugin. Maybe it has to be updated?\n" +
            "Error: #{e.message}.\n" +
            "Backtrace:\n#{e.backtrace.join("\n")}"  
    end
  end
end

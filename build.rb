require 'redcarpet'
require 'pathname'
require 'sassc'
require 'json'
require 'set'

SITE_CONFIG = "site_config.json"
CONFIG = "config.json"

class SiteConfig
  attr_reader :outputDir, :inputDir, :stylesFile, :currentlyBuilt, :mainPage, :posts
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @outputDir = json["output_dir"]
    @inputDir = json["input_dir"]
    @stylesFile = json["styles_file"]
    @mainPage = json["main_page"]
    @currentlyBuilt = Set.new
    @posts = Array.new
  end
end

class Config
  TAG_DELIMITER = ", "
  attr_reader :title, :date, :publish, :tags, :file, :showContents
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @title = json["title"]
    @showContents = json["show_contents"]
    @date = json["date"]
    @publish = json["publish"]
    @tags = json["tags"].split(TAG_DELIMITER)
    @file = json["file"]
  end
end

class Post
  attr_reader :config
  def initialize(dir)
    @config = Config.new(dir+CONFIG)
    @markdown_path = dir + @config.file
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    @markdown_renderer = Redcarpet::Markdown.new(renderer)
  end

  def compile(siteConfig)
    styles_name = stylesFileName(siteConfig)
    styles = "<link rel=\"stylesheet\" href=\"#{styles_name}.css\"/>"

    markdown = File.read(@markdown_path)
    @wordCount = markdown.split(" ").length

    title = "<title>#{@config.title}</title>"
    header = "<!DOCTYPE html><head>#{title}#{styles}</head>"
    body = "havent added contents yet"
    if @config.showContents
      # TODO: add list of contents
    else
      body = "<body>" + @markdown_renderer.render(markdown) + "</body>"
    end
    @html = header + body
  end

  def output(siteConfig)
    if @config.publish
      return @html
    else
      return ""
    end
  end
end

def stylesFileName(siteConfig)
    styles_path = Pathname.new(siteConfig.stylesFile)
    return (styles_path.basename).to_s.split(".").first
end

if __FILE__ == $0
  siteConfig = SiteConfig.new(SITE_CONFIG)
  # reset output directory
  Dir.foreach(siteConfig.outputDir) do |fileName|
    next if fileName == "." or fileName == ".."
    if File.file?(fileName)
      File.delete(siteConfig.outputDir + fileName)
    end
  end

  # output styles files
  sass = File.read(siteConfig.stylesFile)
  css  = SassC::Engine.new(sass, style: :compressed).render
  stylesName = siteConfig.outputDir + stylesFileName(siteConfig) + ".css"
  styleFile = File.open(stylesName, "w")
  styleFile.puts(css)
  styleFile.close()

  # check for duplicate output files and output html files
  Dir.foreach(siteConfig.inputDir) do |postDir|
    next if postDir == "." or postDir == ".."
    fullDir = siteConfig.inputDir + postDir + "/"
    post = Post.new(fullDir)
    post.compile(siteConfig)
    output = post.output(siteConfig)
    if output != ""
      outputFileName = post.config.title.split(" ").join("_") + ".html"
      if siteConfig.currentlyBuilt.add?(outputFileName) == nil
        puts "Found duplicate file name: \"#{outputFileName}\". Writing over last file."
      else
        siteConfig.posts.push(post)
      end
      outputFile = File.open(siteConfig.outputDir + outputFileName, "w")
      outputFile.puts(output)
      outputFile.close()
    end
  end

  # put in correct index.html
  mainPageData = File.read(siteConfig.mainPage)
  mainPageName = siteConfig.outputDir + siteConfig.mainPage
  mainPageFile = File.open(mainPageName, "w")
  mainPageFile.puts(mainPageData)
  mainPageFile.close()
end

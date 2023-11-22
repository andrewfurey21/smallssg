require 'redcarpet'
require 'pathname'
require 'sassc'
require 'json'
require 'set'
require 'nokogiri'

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
  attr_reader :config, :wordCount
  def initialize(dir)
    @config = Config.new(dir+CONFIG)
    @markdown_path = dir + @config.file
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    @markdown_renderer = Redcarpet::Markdown.new(renderer)
  end

  def compile(siteConfig)
    markdown = File.read(@markdown_path)
    @wordCount = markdown.split(" ").length

    rendered_html = @markdown_renderer.render(markdown)
    mainPageData = File.read(siteConfig.mainPage)
    doc = Nokogiri::HTML::Document.parse(mainPageData)
    doc.at("div.post").add_child(rendered_html)

    if @config.showContents
      # TODO: add list of contents
    end
    @html = doc.to_html
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
        puts "Found duplicate file name: \"#{outputFileName}\". Ignoring file."
      else
        siteConfig.posts.push(post)
        outputFile = File.open(siteConfig.outputDir + outputFileName, "w")
        outputFile.puts(output)
        outputFile.close()
      end
    end
  end

  # put in correct index.html
  mainPageData = File.read(siteConfig.mainPage)
  doc = Nokogiri::HTML::Document.parse(mainPageData)

  siteConfig.posts.each do |post|
    contents = Nokogiri::HTML4::Builder.new do |doc|
      doc.div(:class => "articlePost") {
        page = post.config.title.split(" ").join("_") + ".html"
        doc.a(:href => page) {
          doc.span(:class => "date") {
            doc.text "#{post.config.date} "
          }
          doc.text "#{post.config.title}"
        }
      }
    end
    contentsDiv = contents.to_html.split("\n")[1]
    doc.at("div.articles").add_child(contentsDiv)
  end

  mainPageName = siteConfig.outputDir + siteConfig.mainPage
  mainPageFile = File.open(mainPageName, "w")
  mainPageFile.puts(doc)
  mainPageFile.close()
end

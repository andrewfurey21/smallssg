require 'redcarpet'
require 'pathname'
require 'sassc'
require 'json'


DIR_NAME = "public"
MD_DIR = "posts"
STYLES_DIR = "styles"

SITE_CONFIG = "site_config.json"
CONFIG = "config.json"

def generateHTML(pathName, outputDir)
  path = Pathname.new(pathName)
  fileName = ""
  if path.file?
    fileName = (path.basename).to_s.split(".").first + ".html"
    puts "Output file name: " + fileName
  else
    puts "This is not a file, moron."
  end
  file = File.readlines(path)
  renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
  markdown = Redcarpet::Markdown.new(renderer, extensions={})

  html = markdown.render(file.join(''))
  html = "<body>" + html + "</body>"
  html = HEADER + html
  html = "<html>" + html + "</html>"
  html = "<!DOCTYPE html>" + html

  outputFile = File.new(outputDir+"/"+fileName, "w")
  outputFile.puts(html)
  outputFile.close()

  return html
end

# Creates public directory outside of submodule
# TODO: update to fix up files, not reset the whole thing (for version control)
def updatePublicDirectory
  outputDir = "../"+DIR_NAME
  inputDir = "../"+MD_DIR
  Dir.mkdir(outputDir)

  sass = File.readlines("../"+STYLES_DIR+"/main.scss").join('')
  css  = SassC::Engine.new(sass, style: :compressed).render
  cssOutput = File.new(outputDir+"/main.css", "w")
  cssOutput.puts(css)
  cssOutput.close()

  index = File.readlines("../index.html")
  outputFile = File.new(outputDir+"/index.html", "w")
  outputFile.puts(index)
  outputFile.close()

  Dir.foreach(inputDir) do |fileName|
    next if fileName == "." || fileName == ".."
    generateHTML(inputDir+"/"+fileName, outputDir)
  end

end

def compileSassDirectory
  outputDir = "../"+DIR_NAME
  Dir.forEach("../"+STYLE_DIR) do |fileName|
    # why adding .scss?
    sass = File.readlines("../"+STYLES_DIR+"/"+ fileName + ".scss").join('')
    css  = SassC::Engine.new(sass, style: :compressed).render
    cssOutput = File.new(outputDir+"/"+fileName+".css", "w")
    cssOutput.puts(css)
    cssOutput.close()
  end
end

class SiteConfig
  attr_reader :show_contents, :output_dir, :input_dir, :styles_file
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @show_contents = json["show_contents"]
    @output_dir = json["output_dir"]
    @input_dir = json["input_dir"]
    @styles_file = json["styles_file"]
  end
end

class Config
  TAG_DELIMITER = ", "
  attr_reader :title, :date, :publish, :tags, :file
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @title = json["title"]
    @date = json["date"]
    @publish = json["publish"]
    @tags = json["tags"].split(TAG_DELIMITER)
    @file = json["file"]
  end
end

class Post
  def initialize(dir)
    @config = Config.new(dir+CONFIG)
    @markdown_path = dir + @config.file
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    @markdown_renderer = Redcarpet::Markdown.new(renderer)
  end

  # TODO: add list of contents
  def compile(siteConfig)
    title = "<title>#{@config.title}</title>"
    styles_path = Pathname.new(siteConfig.styles_file)
    styles_name = (styles_path.basename).to_s.split(".").first
    styles = "<link rel=\"stylesheet\" href=\"#{styles_name}.css\"/>"
    markdown = File.read(@markdown_path)
    body = "<body>" + @markdown_renderer.render(markdown) + "</body>"
    header = "<!DOCTYPE html><head>#{title}#{styles}</head>"

    @html = header + body
  end

  def output
    if @config.publish
      puts @html
    end
  end
end

siteConfig = SiteConfig.new(SITE_CONFIG)
post = Post.new("posts/post1/")
post.compile(siteConfig)
post.output
# updatePublicDirectory

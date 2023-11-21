require 'redcarpet'
require 'pathname'
require 'sassc'
require 'json'

HEADER = <<END_OF_STRING
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Andrew's Blog</title>
  <link rel="stylesheet" href="main.css">
</head>
END_OF_STRING

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
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @show_contents = json["show_contents"]
    @output_dir = json["output_dir"]
    @input_dir = json["input_dir"]
    @styles_dir = json["styles_dir"]
  end
end

class Config
  def initialize(file)
    data = File.read(file)
    json = JSON.parse(data)
    @title = json["title"]
    @data = json["data"]
    @publish = json["publish"]
    @tags = json["tags"].split(" ")
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

  def compile
    markdown = File.read(@markdown_path)
    @html = markdown_renderer.render(markdown)
  end
end

# updatePublicDirectory

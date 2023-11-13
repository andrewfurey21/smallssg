require 'redcarpet'
require 'pathname'
require 'sassc'

HEADER = <<END_OF_STRING
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Andrew's Blog</title>
  <link rel="stylesheet" href="main.css">
</head>
END_OF_STRING

DIR_NAME = "public"
MD_DIR = "markdown"
STYLES_DIR = "styles"

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

  outputFile = File.new(outputDir+"/"+fileName, "w")
  outputFile.puts(html)
  outputFile.close()

  return html
end

# Creates public directory outside of submodule
def createPublicDirectory
  index = File.readlines("../index.html")
  outputDir = "../"+DIR_NAME
  inputDir = "../"+MD_DIR
  # if not Dir.exist?(outputDir)
  #   Dir.mkdir(outputDir) #TODO: fix if public is already there
  # end
  Dir.mkdir(outputDir)

  sass = File.readlines("../"+STYLES_DIR+"/main.scss").join('')
  css  = SassC::Engine.new(sass, style: :compressed).render
  puts css

  puts outputDir+"/index.html"
  outputFile = File.new(outputDir+"/index.html", "w")
  outputFile.puts(index)
  outputFile.close()

  Dir.foreach(inputDir) do |fileName|
    next if fileName == "." || fileName == ".."
    generateHTML(inputDir+"/"+fileName, outputDir)
  end

end

createPublicDirectory

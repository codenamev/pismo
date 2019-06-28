# encoding: utf-8

require 'helper'

class PismoDocumentTest < Test::Unit::TestCase
  context "Pismo::Document" do
    should "process an IO/File object" do
      doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
      assert doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end

  context "A very basic Pismo document" do
    setup do
      @doc = Document.new(%{<html><body><h1>Hello</h1></body></html>})
    end

    should "pass sanitization" do
      assert_equal %{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">\n<html><body><h1>Hello</h1></body></html>\n}, @doc.html
    end

    should "result in a Nokogiri document" do
      assert @doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end

  context "A basic real world blog post" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
    end

    should "provide a title" do
      assert_equal  "CoffeeScript: A New Language With A Pure Ruby Compiler", @doc.title
    end

    should "provide a title extracted from an og:title meta tag" do
      assert_equal  "CoffeeScript: A New Language With A Pure Ruby Compiler", @doc.og_title
    end

    should "provide a title extracted from the html title tag, stripped of the site name, if possible" do
      assert_equal  "CoffeeScript: A New Language With A Pure Ruby Compiler", @doc.html_title
    end

    should "strip separators and site names from title strings" do
      site_name = "RubyInside"
      title = "CoffeeScript: A New Language With A Pure Ruby Compiler"

      separators = [
        "–",
        "-",
        ":",
        "›",
        "»",
        "|",
        "::",
        "."
      ]

      separators.each do |separator|
        stripped_title = @doc.strip_site_name_and_separators_from("#{site_name} #{separator} #{title}")
        assert_equal stripped_title, title
      end
    end


    should "provide keywords" do
      assert_equal [["code", 4],
                    ["coffeescript", 3],
                    ["compiler", 2],
                    ["github", 2],
                    ["javascript", 2],
                    ["ruby", 5]], @doc.keywords.sort_by{|p| p[0]}
    end
  end

  context "A basic real world blog post with custom user agent" do
    setup do
      @url = 'https://web.archive.org/web/20190310230755/http://www.rubyinside.com/no-true-mod_ruby-is-damaging-rubys-viability-on-the-web-693.html'
      @doc = Document.new(@url, user_agent: 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0')
    end

    should "provide a title" do
      assert_equal  "No True \"mod_ruby\" Is Damaging Ruby's Viability On The Web", @doc.title
    end

    context "with a custom user agent alias" do
      setup do
        @doc = Document.new(@url, user_agent_alias: 'Linux Mozilla')
      end

      should "provide a title" do
        assert_equal  "No True \"mod_ruby\" Is Damaging Ruby's Viability On The Web", @doc.title
      end
    end

    context "with a custom user agent alias as the user_agent" do
      setup do
        @doc = Document.new(@url, user_agent: 'Linux Mozilla')
      end

      should "provide a title" do
        assert_equal  "No True \"mod_ruby\" Is Damaging Ruby's Viability On The Web", @doc.title
      end
    end

    context "with a custom user agent alias as the user_agent" do
      setup do
        @doc = Document.new(@url, user_agent: 'Linux Mozilla')
      end

      should "provide a title" do
        assert_equal  "No True \"mod_ruby\" Is Damaging Ruby's Viability On The Web", @doc.title
      end
    end

    context "with an unknown custom user agent alias" do
      setup do
        @doc = Document.new(@url, user_agent: 'Browser Bob')
      end

      should "provide a title" do
        assert_equal  "No True \"mod_ruby\" Is Damaging Ruby's Viability On The Web", @doc.title
      end
    end
  end


  context "A basic real world blog post with relative images and all_images option set to true" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/relative_imgs.html"), :all_images => true)
    end

    should "get relative images" do
      assert @doc.images.include?('/wp-content/uploads/2010/01/coffeescript.png')
    end
  end

  context "A blog post with videos" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/videos.html"))
    end

    should 'get embed object' do
      videos = @doc.videos
      assert_equal videos.length, 1
      assert_equal videos.first['src'], 'http://www.youtube.com/v/dBtYXFXa5Ig?fs=1&hl=en_US&rel=0&color1=0xFFFFFF&color2=0xFFFFFF&border=0'
    end
  end

end

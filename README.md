# tiny

Tiny is a framework agnostic markup builder. It is useful for defining
view helpers or generating HTML markup using ruby objects, leveraging
inheritance and composition while defining templates.

It is inspired by Erector and Markaby but with a minimalistic aproach
and it opts for evaluating content blocks in their original context
rather than using instance\_eval thus instance variables need not to be
"smuggled in". It also attempts to be a tiny framework for defining view
helpers to be used in ERB and HAML templates from Rails, Sinatra or any
other framework.

It provides a mixin for inline building HTML markup from any class or to
define pure ruby object templates with all object-oriented programming
advantages such as inheritance and encapsulation.

Tiny is pretty much fully documented. Please check [Tiny
Rdoc](http://rdoc.info/github/maca/tiny/master/file/README.md) for more
info.


## Install

    $ gem install tiny

## Usage

    require 'tiny'

    class MyPage < Tiny::Widget
      def markup
        html do
          head do
            title "Hello"
          end
          body do
            h1 "Hello"
            p :class => 'content' do
              text "Lorem ipsum..."
            end
          end
        end
      end
    end
    MyPage.new.to_html
    # => <html>
      <head>
        <title>Hello</title>
      </head>
      <body>
        <h1>Hello</h1>
        <p>
          Lorem ipsum...
        </p>
      </body>
    </html>


## Markup Helpers

There are a few was of generating markup with Tiny, while one is by
encapsulated classes inheriting from `Tiny::Widget`, another one is
doing it inline by including `Tiny::Helpers` in any context.

Including `Tiny::Helpers` gives access to a handfull of methods, the
basic one is `html_tag` aliased as `tag`.

    include Tiny::Helpers

    tag(:ul) do
      tag(:li) do
        tag :a, 'Home', :class => 'home', :href => '/'
      end  
      ...
    end
    # => <ul>
      <li>
        <a class="home" href="/">Home</a>
      </li>
      ...
    </ul>

## HTML tags

Tags are self closed or explicitly closed depeding on the tag name.
Attributes are HTML-escaped and mapped as follows:

    tag(:link, :href => 'my-styles.css')
    # => <link href="my-styles.css" />
    tag(:li, 'Bicycle', :class => ['with-discount', 'in-stock'])
    # => <li class="with-discount in-stock">Bicycle</li>
    tag(:textarea, :disabled => true)
    # => <textarea disabled></textarea>
    tag(:textarea, :disabled => false)
    # => <textarea></textarea>

Tag content can be defined either by passing a string and optionally an
attributes hash or by passing a content block.

## Markup

Other methods for generating markup are `text` for appending HTML
escaped `text`, `text!` or `append!` for appending HTML, `comment`, `cdata`
and `doctype`.

The method `with_buffer` is for capturing template content, just like
Rails `capture` but it also serves for concatenating content.

    with_buffer do
      tag(:h1, "Hello")
      tag(:p, "Lorem ipsum...")
    end
    # => <h1>Hello</h1>
    <p>Lorem ipsum...</p>

## Rails

Tiny ActionView helpers are allready included in ActionView, no further
step is required for using Tiny in Rails view helpers, just use `html_tag`
instead of `tag` because ActionView allready defines `tag`.

You will be able to call `html_tag`, `with_buffer`, `text`, `append!`,
and the rest of Tiny's markup generation methods from your view helper
modules.

The advantage over Rails' markup method such as `tag` and `content_tag` is
that generated strings need not to be explicitly concatenated.

In addition to defining view helpers to be used from templates, a
`Widget` can substitute a template view with the benefit of inheritance.

No template handler es provided but is not cumbersome explicitly
rendering the Widget.
There is no enforcement on where widgets are placed but a logical
place would be under `"#{Rails.root}/app/widgets"` and autoloading the
directory in environment.rb

    $ mkdir app/widgets
    # config/application.rb
    ...
    module MyRailsApp
      class Application < Rails::Application
        ...
        config.autoload_paths += %W(#{config.root}/widgets)
        ...
      end
    end

    # app/widgets/product_list.rb
    class ProductList < Tiny::Widget
    ...
    end

    # app/controllers/products_controller.rb
    controller Products < ApplicationController
      def index
        products = Product.all
        render :text => ProductList.new(products).to_html
      end
      ...
    end

## Sinatra

For using the markup helpers:
    
    class MyApp < Sinatra::Base
      helpers Tiny::Helpers
        
      get '/home' do
        with_buffer do
          doctype
          html do
            ...
          end
        end
      end
    end

Rendering `Tiny::Widgets`
    
    class MyApp < Sinatra::Base
      get '/products' do
        products = Product.all
        MyProductList.new(products).to_html
      end
    end


## Shortcuts

Including `Tiny::HTML` gives access to shortcuts for HTML tags. Caution
must be exercised because its quite a few methods.

## View Inheritance

    class Template < Tiny::Widget
      def markup
        doctype
        html do
          head do
            title @title
          end
          body do
            navigation
            section(:id => 'content') do
              yield
            end
            footer_content
          end
        end
      end

      def navigation
        nav(:id) do
          ul do
            li do
              a('Home', :class => 'home', :href => '/')
            end  
            li do
              a('About', :class => 'about', :href => '/about')
            end  
            li do
              a('Home', :class => 'products', :href => '/products')
            end  
          end
        end
      end
      
      def footer_content
        footer "© 2012"
      end
    end

    class HomePage < Template
      def initialize
        @title = "Home"
      end

      def markup
        super do
          h1 "Welcome!!"
          p "Lorem ipsum..."
        end
      end
    end

    HomePage.new.to_html
    # => <!DOCTYPE html>
    <html>
      <head>
        <title>Home</title>
      </head>
      <body>
        <nav>
          <ul>
            <li>
              <a class="home" href="/">Home</a>
            </li>
            <li>
              <a class="about" href="/about">About</a>
            </li>
            <li>
              <a class="products" href="/products">Home</a>
            </li>
          </ul>
        </nav>
        <section id="content">
          <h1>Welcome!!</h1>
          <p>Lorem ipsum...</p>
        </section>
        <footer>
          © 2012
        </footer>
      </body>
    </html>
 

## View helpers for HAML and ERB templates

One of the Tiny's main goals is providing facilities for defining view
helpers that can be used from Ruby or templating laguages regardless of
the web framework.

A Widget can take a block while calling `to_html`. Tiny can determine
wether the block was originated in an ERB or HAML template or not and
treat it accordingly. #to\_html forwards the passed block to #markup but
concatenates the result of calling it.

    class MyForm < Tiny::Widget
      def initialize(action)
        @action = action
      end

      def markup
        form(:action => @action) do
          fieldset do
            yield(self)
          end
        end
      end

      def text_input(name, value)
        TextInput.new(name, value).to_html
      end
    end

    class TextInput < Tiny::Widget
      def initialize(name, value)
        @name, @value = name, value
      end

      def markup
        label(@name.capitalize, :for => @name)
        input(:type => 'text', :id => @name, :name => @name, :value => @value)
      end
    end

    def my_form(action, &block)
      # the block is forwarded to MyForm#to_html
      MyForm.new(action).to_html(&block) 
    end

Using the helper from an ERB template, note that Tiny allows explicitly
concatenating calls with blocks just like with Rails ERB.

    <%= my_form('/login') do |form| %>
      <%= form.text_input 'email', 'email@example.com' %>
    <% end %>
    # => <form action="/login">
      ...
      <fieldset>
        <label for="email">Email</label>
        <input type="text" id="email" name="email" value="email@example.com" />
      </fieldset>
      ...
    </form>

Using the same helper from Ruby:

    my_form('/login') do |form|
      append! form.text_input 'email', 'email@example.com'
    end
    # => <form action="/login">
      ...
      <fieldset>
        <label for="email">Email</label>
        <input type="text" id="email" name="email" value="email@example.com" />
      </fieldset>
      ...
    </form>

## HTML Representation For Any Object.

By including the `Rendering` any object can emit it's HTML representation.
Whether this is or isn't a good idea is up to you.

    class User < Model
      include Tiny::Rendering
    
      def markup
        div(:id => "user-#{self.id}") do
          img :src => self.avatar_url
          dl do
            dt "First Name"
            dd self.first_name
            dt "Last Name"
            dd self.last_name
          end
        end
      end
    end
    
    user = User.create(:first_name => 'Macario',
      :last_name => 'Ortega',
      :avatar_url => 'http://example.com/profile/dbg.jpeg')
    user.to_html
    # => <div id="user-1">
      <img src="http://example.com/profile/dbg.jpeg" />
      <dl>
        <dt>First Name</dt>
        <dd>Macario</dd>
        <dt>Last Name</dt>
        <dd>Ortega</dd>
      </dl>
    </div>

## No code is better than no code

LOC count.

Erector

    $ cloc erector/lib
    http://cloc.sourceforge.net v 1.56  T=0.5 s (102.0 files/s, 43438.0 lines/s)
    -------------------------------------------------------------------------------
    Language                     files          blank        comment           code
    -------------------------------------------------------------------------------
    Ruby                            51            433            786          20500
    -------------------------------------------------------------------------------
    SUM:                            51            433            786          20500
    -------------------------------------------------------------------------------

Markaby

    $ cloc markaby/lib
    http://cloc.sourceforge.net v 1.56  T=0.5 s (24.0 files/s, 2142.0 lines/s)
    -------------------------------------------------------------------------------
    Language                     files          blank        comment           code
    -------------------------------------------------------------------------------
    Ruby                            12            133            177            761
    -------------------------------------------------------------------------------
    SUM:                            12            133            177            761
    -------------------------------------------------------------------------------


Tiny

    $ cloc tiny/lib
    http://cloc.sourceforge.net v 1.56  T=0.5 s (12.0 files/s, 1650.0 lines/s)
    -------------------------------------------------------------------------------
    Language                     files          blank        comment           code
    -------------------------------------------------------------------------------
    Ruby                             6             71            399            355
    -------------------------------------------------------------------------------
    SUM:                             6             71            399            355
    -------------------------------------------------------------------------------


## LICENSE:

(The MIT License)

Copyright (c) 2012 Macario Ortega

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

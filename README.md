# OMF Web

This Ruby 1.9 gem provides the components for building a web-based data visualization service. 
The typical use case is to allow a user to investigate a data set stored in one or more databases
as well as life data streams.

Installation
------------

At this stage the best course of action is to clone the repository

    % git clone https://github.com/mytestbed/omf_web.git
    % cd omf_web
    % export OMF_WEB=`pwd`
    % bundle install
    
On some systems you will need to install 'libicu'

On Mac with Ports

    % sudo port install icu
    % bundle config build.charlock_holmes --with-icu-dir=/opt/local

Getting Started
---------------

There are a few example sites in the 'example' directory. They have been developed in the context of various demos and 
may not always be kept up to date. The one which should always work is 'example/simple'. Try it out.

    % $OMF_WEB/bin/omf_web_server.rb --config $OMF_WEB/example/simple/simple.yaml start
    
This starts a webserver which can be accessed locally via 'http:localhost:4050'. Connecting to it through your favorite 
web browser should display a web page approx. looking like:

![Screenshot of starting page](https://raw.github.com/mytestbed/omf_web/master/doc/screenshot2.png "Screenshot")

Don't forget to press the icon buttons 
![icon buttons](https://raw.github.com/mytestbed/omf_web/master/doc/widget_detail.png "icon buttons")
on the left widget header.

Overview
--------

The core components are:

* A **DataSource** which holds a specific data set organised as a table. It is defined
by a *Schema* and rows may be dynamically added and removed.
  
* A [**Widget**](#widgets) which defines what is displayed on parts of a web page. 

* A **Renderer** which defines the conversion of a widget's state into HTML.

* A **Theme** which defines what renderes to use to maintain a common look and feel
across a single web site.

A visualization web site based on this components is normally deployed on a rack-based
web server, such as [Thin](http://code.macournoyer.com/thin/). 
A sample *config.ru* file can be found in the gem's
"lib/omf-web" directory.

The core component is the Widget. It defines the structure of the web site and also maintains
session state. Widgets fall roughly into two categories. The *content* widgets define what is 
shown in a certain area on a page, while the *layout* widget define how all the content widgets
are arranged. A web site is defined by a tree of widgets where the internal nodes of the tree are layout 
widgets and the leaf nodes are content widget.

This tree is normally defined by one or more YAML files which at start-up are loaded into 

    wd = YAML.load_file(file_name)
    OMF::Web.register_widget wd[:widget]
   
where a basic configuration file would look like:

    widget:
      name: Main
      top_level: true
      type: layout/tabbed
      widgets: 
        - name: Ping Line
          type: data/line_chart3
          data_source: 
            name: ping
          mapping:
            x_axis: oml_ts_client
            y_axis: rtt
                    
        - name: Table
          type: data/table2
          data_source: 
            name: ping
            
and results in a web site as shown below:

__add screen shot here__

## Widgets <a id="widgets"/>

The above configuration file describes three widgets. A *layout* widget of type "layout/tabbed" and two *content*
widget of type "data/line_chart3" and "data/table2" respectively. A *tabbed* layout will show one its content
widgets and provide a selector for the user to switch between the available ones. In the above example, the 
choices are "Ping Line" and "Table". 

The content widgets in the above example are both data widgets. Data widgets are associated with one or more 
data sources. The sub type (separated by a "/") defines the visualizaton method used. In the above example, the 
content of the data source "ping" can be visualized both as a line chart ("type/line_chart3") or in a table
format ("type/table"). Most widgets will require additional parameter settings. For instance, the line chart needs
to be instructed which of the columns of the the *data_source* should be mapped to which coordinate ("mapping").

All widget share the following configuration options:


* __id: string__ (optional)
Each widget can be given an id which needs to be unique within a web application. A widget can be 
inserted into the widget tree at more than one location by refering to it's ID via the __id_ref__ option. 

* __name: string__ (required)
The name of a widget is often used by the Theme to label a widget.

* __type: string__ (required)
The type defines the type of widget to be used.

## Layout Widgets <a id="layout_widgets"/>

A layout widget implements a specific strategy to arrange its children widget within a certain part of a web page.
It is permissble for some or all of the children widgets to be layout widgets themselves. 

All layout widgets are of type 'layout' with an additional sub type identifying the specific layout startegy. They also 
share the following configuration options:

* __top_level: boolean__ (optional)
When set to true it defines the layout of an entire web page. It will be up to the associated Theme to list all
defined pages (top-level widgets) and how to switch between them.

* __priority: integer__ (optional)
The priority is only relevant when top_level is set to true and defines the ranking order among all top level
layouts. It is normally used by the Theme to rank the list of pages.

* __widgets: array of widgets__ (required)
The widgets option takes an array of widget defintions or references to widgets defined somewhere else.

* __render: array of render options__ (optional)
Render options are used by the _Theme_ to control various aspects of how the layout and its children are being 
rendered. See the documention of the respective _Theme_ for further information.

The following layout widgets are currently available:

* [One column layout](#one_column_layout) 
* [Two column layout](#two_column_layout)
* [Flow layout](#flow_layout)
* [Tabbed layout](#tabbed_layout)
* [Stacked layout](#stacked_layout)

### One Column Layout (type: layout/one_column)<a id="one_column_layout"/>

The one column layout arranges its children in a vertical session with each children widget being able to 
span the entire width given to its parent.

### Two column layout (type: layout/two_columns/XX_YY)<a id="two_column_layout"/>

The two column layout splits its layout space into two columns and renders a _left_ array of widgets in the 
left column, and a _right_ array of widgets in the right column. Each column is rendered identical to 
the behavior defined in the one column layout. The third level type declaration defines on how the space is
divided among the two columns. The following options are available where the first number defines the portion
in percent taken up by the left column and the right column given the reminder.

* layout/two_columns/50_50
* layout/two_columns/66_33
* layout/two_columns/33_66
* layout/two_columns/75_25
* layout/two_columns/25_75

The __widgets__ option should contain two named arrays, __left__ and __right__, each containing a list of widgets
to be rendered vertically in the respective column.

### Flow Layout <a id="flow_column_layout"/>

The flow layout arranges its widgets first horizontally from left to right. If a widget's width would exceed 
the width of the entire layout, it will be rendered at the left edge of a new "line" below the previous widgets.
Changing the width of the layout image may result in a reflow of all the widgets.

### Tabbed Layout <a id="tabbed_column_layout"/>

A tabbed layout is only rendering one of the widgets and a theme-dependent mechanism to select which widget is being shown. 
Selecting a new widget will likely result in a new page request from the server. However, this is up to the  

### Stacked Layout <a id="stacked_column_layout"/>

A stacked layout is very similar as the tabbed layout as it only shows one of its children widgets at any time. The main 
difference is in how the Theme renders it. As a general rule, a stacked layout is used for providing multiple,
alternative represenatations of the same data set. As a consequence, the theme will provide a 'light' switching
mechanism using the same surrounding chrome, often including a common title. By refering to the same data set, 
switching among presetnation styles will normally not require a call back to the server.

## Content Widgets <a id="content_widgets"/>

_Some Introductory Text_

The following content widgets are currently available:

* [Data widget](#data_widget) 

### Data Widget <a id="data_widget"/>

* __data_source__: _data_source_ (required)
The data source providing the data to be visualised by this widget. See ??? for a more
thorough description of the additonal parameters to further describe the data source in
the context of this widget.

* __mapping__: _mapping_decl_ (required)
Declares the mapping of columns in the data source to visual properties of the widget.



-------------------------------------------------------------------------------------
 ** These notes are way out of date. Look at the 'demo' example for some guidance **

This module is used to define and run a web server which allows a user to explore and
intereact with various experiments. It is a stand-alone unit communicating through
the OMF messaging framework with other entities.

The content of such a web site consists of

* A +Page+ which is essentially representing a context, most likely that of a
  a single experiment.

* Pages can contain multiple +Cards+. The containing Page will contain
  navigational elements to switch between those cards

* Each card contains one or more +Widgets+ which are arranged by an
  associated +Formatter+ implementing a certain layout.

* A +Session+ represents the context of a specific user of the server. Users
  may be associated with different privileges (not implemented) which determine
  what pages they can see (and interact) and also what cards and widgets

* Theme ... explain

The actual session state is kept in the widgets. The card description (defCard)
defines the formatter to use and the type of widgets to populate it with. The
respective widgets are initialised the first time such a card is rendered
within a user session and kept in the session to be reused the next time
the user requests the card. The primary decision for this design is the fact
that many widgets visualize dynamic state and any updates to that should be
propagated to the user's web browser if that widget instance is visisble there.
Therefore, many widgets either establish web sockets back to the server or
issue periodic AJAX calls. Maintaining interal widget state will also speed
up the rendering of a specific card. The drawback of this design is that it
can create substantial state for each user session. Given the envisioned use
case this is not really a concern as the number of active sessions will be small.
However, we do envision use cases where the server will run for a long time, which
in term will require pruning of 'dead' sessions and the associated freeing of
state.

With such a desing the main extension point will be around widgets and to a lesser
extend around formaters and themes.

As the primary objective of this package is to visualize and interact with dynamic
system state we introduce a few more concepts.

* An +Event+ is a time-stamped tuple (hash) which describes the properties of a
  specific event whch occured at a certain time (timestamp).

* An +EventList+ which holds an (ordered ?) list of Events with every event belonging
  to the same schema. It will be the primary source of information for widgets.

  It provides means for other objects to subscribe to receive notification when the
  list changes. There is also an associated policy on how to maintain the list
  (e.g. keep only the last N recent events). In addition, an event list may subscribe
  to the OMF messaging framework to receive events created by system and other
  experiment services.


# OSXWebViewCache

OSXWebViewCache is a framework written in Objective-C which enables caching of (static) URL resources requested by an OSX webview (suitable when building hybrid applications).

It expands upon the concepts and code in [this](https://www.raywenderlich.com/59982/nsurlprotocol-tutorial) article.  

### Features

* Caches URL resources on a per-domain basis.

* Updates cached resources only when they are modified (using the "Last-Modified" HTTP header).

* Serves cached resources when internet connectivity is unavailable.

### Usage

1. The project contains two targets, the OSXWebViewCache framework and a sample application ('Driver'). After building the project, drag and drop the OSXWebViewCache framework into your own project to use it. 

2. Use the framework as follows:

	```objective-c
	#import <OSXWebViewCache/CachedURLProtocol.h>

	// ...

	// register the domain 'example.com' to cache static resources for it and all its subdomains.
	[CachedURLProtocol setDomains:@[@"http://example.com"]];

	// register the CachedURLProtocol class (subclass of NSURLProtocol) to handle requests for the registered domain.
    [NSURLProtocol registerClass:[CachedURLProtocol class]];
    ```

Also see the Driver sample application for more details.

### License

The MIT License (MIT)

Copyright (c) 2016 Marc Klefter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
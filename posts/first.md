# How is this blog working ?

Hi there. Happy to see you there. I didn't have much inspiration for the first article, so I thought the first post on this site would be about how this blog works.

The technology used is *Blazor WebAssembly*. All the code runs **solely** on your machine - the server is just there to send you all the code.

I write the blog posts in .md files that are hosted on a Github repository. Once I've finished a post, I add the post's URL to another text file that's only there to reference all the posts on this blog.

What happens when you load the site, and especially when you load this page, is that your web browser makes an HTTP request to the first file, which contains the list of all the blog posts, and then makes as many requests as necessary to retrieve the individual blog posts.

I imagine that this method is highly susceptible to `XSS` vulnerabilities, since raw text written in markdown is rendered in files hosted elsewhere and retrieved via HTTP directly in your browser. However, as this isn't a sensitive site at all, the risks are lower I imagine, unless I have some big enemies in this world.

Anyway, the source code for all this is available on my Github, which I invite you to visit.

I hope this little explanation of how this site works has given you some ideas for making your own blog without paying millions of euros for web hosting for CMS like Wordpress or others.

gabyfle.


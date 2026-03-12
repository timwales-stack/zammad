# Black Raven Service Desk — Custom Branding Initializer
# Injects Black Raven CSS into all Zammad page layouts
Rails.application.config.after_initialize do
  # Inject custom CSS link into the desktop and legacy layouts via middleware
  Rails.application.config.middleware.insert_before(0, Class.new do
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      if headers['content-type']&.include?('text/html')
        body = +""
        response.each { |part| body << part }

        css_link = '<link rel="stylesheet" href="/assets/blackraven-theme.css" />'
        body.sub!('</head>', "#{css_link}\n</head>")

        headers['content-length'] = body.bytesize.to_s
        response = [body]
      end

      [status, headers, response]
    end
  end)
end

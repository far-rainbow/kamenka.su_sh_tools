curl -X DELETE "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/purge_cache" \
    -H "X-Auth-Email: user@example.com" \
    -H "X-Auth-Key: c2547eb745079dac4190b638f5e225cf483cc5cfdda41" \
    -H "Content-Type: text/font" \
    --data '{"files":["http://www.example.com/css/styles.css",{"url":"http://www.example.com/cat_picture.jpg","headers":{"Origin":"example.net"}}]}'

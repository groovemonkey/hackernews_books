require 'rubygems'
require 'httparty'
require 'json'
require 'prawn'
require 'date'
require 'cgi'


def hash_to_comment(h)
    if h['text']
        clean_text = CGI.unescape_html(h['text'])
        # not so pretty, sorry about the long line
        return {
            time: """#{Time.at(h['time']).to_datetime.strftime("%B %e, %Y")} (comment #{h['id']}#{h['parent'] ? (", in response to comment " + h['parent'].to_s) : ""})""",
            text: clean_text
        }
    else
        return {
            time: "ERROR; text was:",
            text: h['text']
        }
    end
end


USERNAME = ARGV[0] || "bespoke_engnr"
MAX_TO_FETCH = ARGV[1]
 
puts "Username: #{USERNAME} max to fetch: #{MAX_TO_FETCH || "all"}"
 
user_url = "https://hacker-news.firebaseio.com/v0/user/#{USERNAME}.json"
comment_url = "https://hacker-news.firebaseio.com/v0/item/$ID.json"
 
user_results = HTTParty.get(user_url).parsed_response
 
comment_ids = user_results["submitted"]
 
puts comment_ids.inspect

 
to_fetch = MAX_TO_FETCH ? MAX_TO_FETCH.to_i : comment_ids.size
to_fetch = [to_fetch, comment_ids.size].min

sample_ids = comment_ids[0..(to_fetch - 1)]

count = 0

increment = (sample_ids.size / 1000.0 + 0.5).to_i
increment = 1 if increment < 1


Prawn::Document.generate("comments/#{USERNAME}.pdf") do
    font("Helvetica")
    default_leading 5

    # title page
    move_down 90
    font_size(45) { text "The Book of #{USERNAME}", :align => :center }
    move_down 120
    font_size(25) { text "hackernews comments #{sample_ids.min} through #{sample_ids.max}", :align => :center }
    start_new_page

    # comment-writing loop
    sample_ids.map do |id|
        comment_url_to_get = comment_url.sub("$ID", id.to_s)
        response = HTTParty.get(comment_url_to_get).parsed_response #rescue nil
        # sleep 0.2
        if response
            count += 1
            # write response hash to PDF
            c = hash_to_comment(response)

            # write the comment
            move_down 10
            font_size(15) { text c[:time] }
            text c[:text]

            # horizontal rule
            move_down 20
            stroke_horizontal_rule

            puts "Downloaded #{count} comments of #{comment_ids.size}." if count % increment == 0
        end
    end
end


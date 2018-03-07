require 'dependencies'

module InstaScrape
  extend Capybara::DSL

  class InstaScrapeError < StandardError; end
  class PrivateAccountError < InstaScrapeError; end
  class NoPostsError < InstaScrapeError; end

  # get a hashtag
  def self.hashtag(hashtag, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    @posts = []
    scrape_posts(include_meta_data: include_meta_data)
  end

  # get a location
  def self.location(location, include_meta_data: false)
    visit "https://www.instagram.com/explore/locations/#{location}/"
    @posts = []
    scrape_posts(include_meta_data: include_meta_data)
  end

  # long scrape a hashtag
  def self.long_scrape_hashtag(hashtag, scrape_length, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    @posts = []
    long_scrape_posts(scrape_length, include_meta_data: include_meta_data)
  end

  # long scrape a hashtag
  def self.long_scrape_user_posts(username, scrape_length, include_meta_data: false)
    @posts = []
    long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data)
  end

  # get user info and posts
  def self.long_scrape_user_info_and_posts(username, scrape_length, include_meta_data: false)
    scrape_user_info(username)
    long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data)
    @user = InstaScrape::InstagramUserWithPosts.new(username, @image, @post_count, @follower_count, @following_count, @description, @posts)
  end

  # get user info
  def self.user_info(username)
    scrape_user_info(username)
    @user = InstaScrape::InstagramUser.new(username, @image, @post_count, @follower_count, @following_count, @description)
  end

  # get user info and posts
  def self.user_info_and_posts(username, include_meta_data: false)
    scrape_user_info(username)
    scrape_user_posts(username, include_meta_data: false)
    @user = InstaScrape::InstagramUserWithPosts.new(username, @image, @post_count, @follower_count, @following_count, @description, @posts)
  end

  # get user posts only
  def self.user_posts(username, include_meta_data: false)
    scrape_user_posts(username, include_meta_data: include_meta_data)
  end

  # get user follower count
  def self.user_follower_count(username)
    scrape_user_info(username)
    @follower_count
  end

  # get user following count
  def self.user_following_count(username)
    scrape_user_info(username)
    @following_count
  end

  # get user post count
  def self.user_post_count(username)
    scrape_user_info(username)
    @post_count
  end

  # get user description
  def self.user_description(username)
    scrape_user_info(username)
    @description
  end

  private

  # post iteration method

  def self.iterate_through_posts(include_meta_data:)
    posts = all('article div div div a').collect do |post|
      { link: post['href'],
        image: post.find('img')['src'],
        text: post.find('img')['alt'] }
    end

    posts.first(9).each do |post|
      if include_meta_data
        visit(post[:link])
        date = page.find('time')['datetime']
        username = page.first('article header div div a')['title']
        hi_res_image = page.all('img').last['src']
        likes = reverse_human_to_number(page.first('div section span span')['innerHTML'])
        info = InstaScrape::InstagramPost.new(post[:link], post[:image],
                                              date: date,
                                              text: post[:text],
                                              username: username,
                                              hi_res_image: hi_res_image,
                                              likes: likes)
      else
        info = InstaScrape::InstagramPost.new(post[:link], post[:image], text: post[:text])
      end
      @posts << info
    end

    # log
    # self.log_posts
    # return result
    @posts
  end

  # user info scraper method
  def self.scrape_user_info(username)
    visit "https://www.instagram.com/#{username}/"
    if page.status_code == 200
      @image = page.find('article header div img')['src']
      within('header') do
        post_count_html = page.first('span', text: 'post')['innerHTML']
        @post_count = reverse_human_to_number(get_span_value(post_count_html))
        follower_count_html = page.first('span', text: 'follower')['innerHTML']
        @follower_count = reverse_human_to_number(get_span_value(follower_count_html))
        following_count_html = page.first('span', text: 'following')['innerHTML']
        @following_count = reverse_human_to_number(get_span_value(following_count_html))

        if page.has_xpath?('//header/section/div[2]')
          description = page.first(:xpath, '//header/section/div[2]')['innerHTML']
          @description = Nokogiri::HTML(description).text
        end
      end
    end
  end

  # scrape posts
  def self.scrape_posts(include_meta_data:)
    check_account(page)
    page.find('a', text: 'Load more', exact: true).click
    max_iteration = 10
    iteration = 0
    while iteration < max_iteration
      iteration += 1
      page.execute_script 'window.scrollTo(0,document.body.scrollHeight);'
      sleep 0.1
      page.execute_script 'window.scrollTo(0,(document.body.scrollHeight - 5000));'
      sleep 0.1
    end
    iterate_through_posts(include_meta_data: include_meta_data)
  rescue Capybara::ElementNotFound => e
    begin
      iterate_through_posts(include_meta_data: include_meta_data)
    end
  end

  def self.long_scrape_posts(scrape_length_in_seconds, include_meta_data:)
    check_account(page)
    page.find('a', text: 'Load more', exact: true).click
    max_iteration = (scrape_length_in_seconds / 0.3)
    iteration = 0
    @loader = '.'
    while iteration < max_iteration
      puts "InstaScrape is working. Please wait.#{@loader}"
      iteration += 1
      sleep 0.1
      page.execute_script 'window.scrollTo(0,document.body.scrollHeight);'
      sleep 0.1
      page.execute_script 'window.scrollTo(0,(document.body.scrollHeight - 5000));'
      sleep 0.1
      @loader << '.'
      system 'clear'
    end
    iterate_through_posts(include_meta_data: include_meta_data)
  rescue Capybara::ElementNotFound => e
    begin
      iterate_through_posts(include_meta_data: include_meta_data)
    end
  end

  def self.long_scrape_user_posts_method(username, scrape_length_in_seconds, include_meta_data:)
    @posts = []
    visit "https://www.instagram.com/#{username}/"
    long_scrape_posts(scrape_length_in_seconds, include_meta_data: include_meta_data)
  end

  def self.scrape_user_posts(username, include_meta_data:)
    @posts = []
    visit "https://www.instagram.com/#{username}/"
    scrape_posts(include_meta_data: include_meta_data)
  end

  # post logger
  def self.log_posts
    post = @posts.sample
    puts '* Printing Sample Post *'
    puts "\n"
    puts "Link: #{post.link}\n"
    puts "Image: #{post.image}\n"
    puts "Text: #{post.text}\n"
    if post.date
      puts "Date: #{post.date}\n"
      puts "Username: #{post.username}\n"
      puts "Hi Res Image: #{post.hi_res_image}\n"
      puts "Likes: #{post.likes}\n"
    end
    puts "\n"
  end

  # split away span tags from user info numbers
  def self.get_span_value(element)
    begin_split = '">'
    end_split = '</span>'
    element[/#{begin_split}(.*?)#{end_split}/m, 1]
  end

  # notify that the account requested is private
  def self.check_account(page)
    title = page.find('h2').text.strip
    if title.eql?('This Account is Private')
      raise PrivateAccountError, 'This account is private!'
    elsif title.eql?('No posts yet.')
      raise NoPostsError, 'This account has no posts!'
    else
      false
    end
  end

  def self.reverse_human_to_number(number)
    if number.to_i.to_s == number.to_s
      number.to_i
    elsif (number =~ /\,\d{3}/o) == 1
      number.gsub(/,(?=\d{3}\b)/, '').to_i
    elsif number.include?('k')
      (number.to_f * 1000).to_i
    elsif number.include?('m')
      (number.to_f * 1_000_000).to_i
    end
  end
end

class TSheets::Results
  include Enumerable

  attr_accessor :url, :options, :model, :cache, :page, :repo,
    :bridge, :name, :index, :loaded, :has_more, :is_singleton, :mode

  alias_method :all, :to_a

  def initialize(url, options, repo, bridge, cache, is_singleton = false, mode = :list)
    self.url = url
    self.options = options
    self.repo = repo
    self.model = repo.model
    self.name = "#{TSheets::Helpers.class_to_endpoint(model)}#{is_singleton ? '' : 's'}"
    self.index = -1
    self.loaded = []
    self.bridge = bridge
    self.cache = cache
    self.has_more = true
    self.is_singleton = is_singleton
    self.mode = mode
    self.page = 1
  end

  def each
    return enum_for(:each) unless block_given?
    while (self.index += 1) < self.loaded.count || (self.has_more && load_next_batch)
      yield self.loaded[self.index]
    end
    self.index = -1
  end

  def load_next_batch
    options = self.options.merge(page: self.page) if !self.repo.filters[:page].nil?
    response = self.bridge.next_batch(self.url, self.name, options, self.is_singleton, self.mode)
    batch = response[:items]
    self.has_more = !self.is_singleton && self.mode == :list && response[:has_more]
    if self.is_singleton
      self.loaded = [ self.model.from_raw(batch, self.cache, response[:supplemental] || {}) ]
    else
      self.loaded += batch.map { |o| self.model.from_raw(o, self.cache, response[:supplemental] || {}) }
    end
    self.page += 1
    batch != [] && batch != {}
  end

end

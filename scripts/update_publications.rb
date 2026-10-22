# encoding: UTF-8
require "cgi"
require "date"
require "json"
require "net/http"
require "optparse"

module Publications
  ROOT = File.expand_path("..", __dir__)
  CATEGORIES = {
    "journal" => ["Journal articles", "Artículos en revistas"],
    "chapter" => ["Book chapters", "Capítulos de libro"],
    "conference" => ["Conference contributions", "Contribuciones a congresos"]
  }.freeze

  def self.arguments(text, offset, count)
    values = []
    count.times do
      offset += 1 while text[offset]&.match?(/\s/)
      raise "Expected LaTeX argument at #{offset}" unless text[offset] == "{"
      start = offset += 1
      depth = 1
      while depth.positive? && offset < text.length
        unless offset.positive? && text[offset - 1] == "\\"
          depth += 1 if text[offset] == "{"
          depth -= 1 if text[offset] == "}"
        end
        offset += 1
      end
      raise "Unbalanced LaTeX argument" unless depth.zero?
      values << text[start...(offset - 1)]
    end
    values
  end

  def self.plain(text)
    result = text.gsub(/\\([&_])/, '\1').gsub(/--/, "–")
    loop do
      cleaned = result.gsub(/\\(?:textbf|textit|textnormal)\{([^{}]*)\}/, '\1')
      break if cleaned == result
      result = cleaned
    end
    raise "Unsupported LaTeX in publication: #{result}" if result.match?(/[\\{}]/)
    result.gsub(/\s+/, " ").strip
  end

  def self.import_cv(path)
    cv = File.read(path, encoding: "UTF-8")
    boundaries = [
      ["journal", "\\section{Journal publications", "\\section{Book chapters", "\\cvEntryNTPL"],
      ["chapter", "\\section{Book chapters", "\\section{Peer", "\\cvEntryNTPL"],
      ["conference", "\\section{Peer", "\\section{Participation in seminars", "\\cvConferencePub"]
    ]
    boundaries.flat_map do |category, start_marker, end_marker, command|
      start = cv.index(start_marker) or raise "Missing #{start_marker}"
      finish = cv.index(end_marker, start + start_marker.length) or raise "Missing #{end_marker}"
      section = cv[start...finish]
      section.enum_for(:scan, /#{Regexp.escape(command)}(?=\s*\{)/).map do
        fields = arguments(section, Regexp.last_match.end(0), 4)
        citation = category == "conference" ? "#{fields[1]} #{fields[2]}" : fields[2]
        urls = citation.scan(/\\url\{([^}]*)\}/).flatten
        dois = urls.map { |url| url.sub(%r{\Ahttps://doi.org/}i, "") if url.match?(%r{\Ahttps://doi.org/}i) }.compact
        raise "Multiple DOIs in one CV entry" if dois.length > 1
        citation = plain(citation.gsub(/\\url\{[^}]*\}/, ""))
        year = category == "conference" ? citation.scan(/\b20\d{2}\b/).last : citation[/\A\((20\d{2})\)/, 1]
        raise "Missing year for #{fields[0]}" unless year
        {
          "category" => category, "title" => plain(fields[0]), "citation" => citation,
          "year" => year.to_i, "doi" => dois.first&.gsub("\\_", "_"), "metrics" => nil
        }
      end
    end
  end

  def self.refresh(records)
    records.each do |record|
      unless record["doi"]
        record["metrics"] = { "status" => "no-doi" }
        next
      end
      uri = URI("https://api.crossref.org/works/#{URI::DEFAULT_PARSER.escape(record.fetch("doi"))}")
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "RafaelEudave-Publications/1.0 (https://r-eudave.github.io/)"
      request["Accept"] = "application/json"
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) { |http| http.request(request) }
      if response.code == "404"
        warn "Crossref has no record for #{record.fetch("doi")}"
        record["metrics"] = { "status" => "not-indexed", "retrieved_at" => Date.today.iso8601 }
      else
        raise "Crossref request failed: HTTP #{response.code} for #{record.fetch("doi")}" unless response.code == "200"
        work = JSON.parse(response.body).fetch("message")
        raise "Crossref returned a different DOI" unless work.fetch("DOI").casecmp?(record.fetch("doi"))
        count = work["is-referenced-by-count"]
        raise "Missing or invalid Crossref citation count for #{record.fetch("doi")}" unless count.is_a?(Integer) && count >= 0
        record["metrics"] = {
          "status" => "available", "citations" => count,
          "retrieved_at" => Date.today.iso8601, "source_url" => uri.to_s
        }
        puts "#{record.fetch("doi")}: #{count} Crossref citations"
      end
      sleep 0.3
    end
  end

  def self.escape(text)
    CGI.escapeHTML(text.to_s)
  end

  def self.metric_html(record)
    metric = record["metrics"] || { "status" => "not-retrieved" }
    case metric.fetch("status")
    when "available"
      count = metric.fetch("citations")
      raise "Invalid citation count" unless count.is_a?(Integer) && count >= 0
      noun_en, noun_es = count == 1 ? ["citation", "cita"] : ["citations", "citas"]
      %(<a class="publication-metric" href="#{escape(metric.fetch("source_url"))}"><span data-es="#{count} #{noun_es} en Crossref">#{count} Crossref #{noun_en}</span> ↗</a> <span class="metric-date"><span data-es="Consultado">Retrieved</span> <time datetime="#{escape(metric.fetch("retrieved_at"))}">#{escape(metric.fetch("retrieved_at"))}</time></span>)
    when "no-doi"
      %(<span class="publication-metric" data-es="Métricas no disponibles: no se indica DOI en el CV.">Metrics unavailable: no DOI listed in the CV.</span>)
    when "not-indexed"
      %(<span class="publication-metric" data-es="Métricas no disponibles: DOI no encontrado en Crossref.">Metrics unavailable: DOI not found in Crossref.</span> <span class="metric-date"><span data-es="Consultado">Retrieved</span> <time datetime="#{escape(metric.fetch("retrieved_at"))}">#{escape(metric.fetch("retrieved_at"))}</time></span>)
    when "not-retrieved"
      %(<span class="publication-metric" data-es="Métricas aún no consultadas.">Metrics not yet retrieved.</span>)
    else
      raise "Unknown metric status: #{metric.fetch("status")}"
    end
  end

  def self.render(records)
    CATEGORIES.map do |category, labels|
      selected = records.select { |record| record.fetch("category") == category }
      entries = selected.map do |record|
        title = escape(record.fetch("title"))
        title = %(<a href="https://doi.org/#{escape(record.fetch("doi"))}">#{title} <span aria-hidden="true">↗</span></a>) if record["doi"]
        %(<li class="publication-entry"><p class="publication-year">#{record.fetch("year")}</p><h3>#{title}</h3><p class="publication-citation">#{escape(record.fetch("citation"))}</p><p class="publication-metrics">#{metric_html(record)}</p></li>)
      end.join("\n")
      %(<section class="publication-category" id="#{category}" aria-labelledby="#{category}-title"><h2 id="#{category}-title"><span data-es="#{labels[1]}">#{labels[0]}</span> <span class="publication-count">(#{selected.length})</span></h2><ol class="publication-list">\n#{entries}\n</ol></section>)
    end.join("\n")
  end

  def self.run(argv)
    options = {}
    OptionParser.new do |parser|
      parser.on("--import-cv PATH") { |path| options[:cv] = path }
      parser.on("--source-revision SHA") { |sha| options[:revision] = sha }
      parser.on("--refresh") { options[:refresh] = true }
    end.parse!(argv)
    data_path = File.join(ROOT, "publications.json")
    if options[:cv]
      raise "--source-revision is required for import" unless options[:revision]
      data = { "source_revision" => options[:revision], "records" => import_cv(options[:cv]) }
    else
      data = JSON.parse(File.read(data_path, encoding: "UTF-8"))
    end
    records = data.fetch("records")
    raise "Publication list is empty" if records.empty?
    dois = records.map { |record| record["doi"]&.downcase }.compact
    raise "Duplicate DOI in publication list" unless dois.uniq.length == dois.length
    raise "Unknown publication category" unless records.all? { |record| CATEGORIES.key?(record["category"]) }
    refresh(records) if options[:refresh]
    page_path = File.join(ROOT, "publications.html")
    page = File.read(page_path, encoding: "UTF-8")
    marker = /<!-- PUBLICATIONS:START -->.*?<!-- PUBLICATIONS:END -->/m
    raise "Missing publication page markers" unless page.match?(marker)
    page = page.sub(marker) { "<!-- PUBLICATIONS:START -->\n#{render(records)}\n<!-- PUBLICATIONS:END -->" }
    File.write(data_path, JSON.pretty_generate(data) + "\n", encoding: "UTF-8")
    File.write(page_path, page, encoding: "UTF-8")
    puts "Rendered #{records.length} publications."
  end
end

Publications.run(ARGV) if $PROGRAM_NAME == __FILE__

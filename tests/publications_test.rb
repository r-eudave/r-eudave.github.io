# encoding: UTF-8
require "minitest/autorun"
require_relative "../scripts/update_publications"

class PublicationsTest < Minitest::Test
  def test_nested_latex_arguments_and_escaped_braces
    assert_equal ["A {nested} title", "\\textbf{An author}", "\\{literal\\}", ""],
                 Publications.arguments('{A {nested} title}{\\textbf{An author}}{\\{literal\\}}{}', 0, 4)
  end

  def test_unbalanced_arguments_fail_explicitly
    assert_raises(RuntimeError) { Publications.arguments("{unfinished", 0, 1) }
  end

  def test_plain_preserves_unicode_and_decodes_latex
    assert_equal "Ramírez Eudave, R. Policy & Practice",
                 Publications.plain("\\textbf{Ramírez Eudave, R.} \\textit{Policy \\& Practice}")
  end

  def test_zero_citations_are_not_missing_metrics
    record = { "metrics" => { "status" => "available", "citations" => 0,
                            "retrieved_at" => "2026-10-22", "source_url" => "https://api.crossref.org/works/10.1/example" } }
    assert_includes Publications.metric_html(record), "0 Crossref citations"
    refute_includes Publications.metric_html(record), "unavailable"
    assert_includes Publications.metric_html("metrics" => { "status" => "no-doi" }), "no DOI listed"
    assert_includes Publications.metric_html("metrics" => { "status" => "not-indexed", "retrieved_at" => "2026-10-22" }), "DOI not found"
  end

  def test_invalid_metric_status_is_not_silently_hidden
    assert_raises(RuntimeError) { Publications.metric_html("metrics" => { "status" => "error" }) }
  end

  def test_full_source_counts_and_metric_provenance
    data = JSON.parse(File.read(File.join(Publications::ROOT, "publications.json"), encoding: "UTF-8"))
    records = data.fetch("records")
    assert_equal({ "journal" => 21, "chapter" => 6, "conference" => 9 }, records.group_by { |record| record["category"] }.transform_values(&:length))
    assert_equal 29, records.count { |record| record["doi"] }
    records.each do |record|
      refute_empty record.fetch("title")
      refute_empty record.fetch("citation")
      metric = record.fetch("metrics")
      if metric["status"] == "available"
        assert_operator metric.fetch("citations"), :>=, 0
        assert_equal record.fetch("doi").downcase,
                     URI::DEFAULT_PARSER.unescape(URI(metric.fetch("source_url")).path.delete_prefix("/works/")).downcase
        Date.iso8601(metric.fetch("retrieved_at"))
      else
        assert_includes ["no-doi", "not-indexed"], metric.fetch("status")
      end
    end
    page = File.read(File.join(Publications::ROOT, "publications.html"), encoding: "UTF-8")
    assert_equal 36, page.scan('class="publication-entry"').length
    assert_includes page, Publications.render(records)
  end

  def test_cv_page_is_linked_and_contains_key_supplied_content
    root = Publications::ROOT
    cv = File.read(File.join(root, "cv.html"), encoding: "UTF-8")
    homepage = File.read(File.join(root, "index.html"), encoding: "UTF-8")
    publications = File.read(File.join(root, "publications.html"), encoding: "UTF-8")
    assert_includes homepage, 'href="cv.html" data-local-page'
    assert_includes publications, 'href="cv.html" data-local-page'
    assert_includes cv, '<html lang="en">'
    %w[Education Work\ experience Awards Professional\ affiliations Skills Languages
       Training Software Teaching Publications].each do |section|
      assert_includes cv.downcase, section.tr("\\", "").downcase
    end
    assert_includes cv, "Rafael Ramírez Eudave, PhD"
    assert_includes cv, "Marie Skłodowska-Curie Postdoctoral Fellow"
    assert_includes cv, "View publications and metrics"
    refute_includes cv, "(+31) 6 344 34 984"
  end
end

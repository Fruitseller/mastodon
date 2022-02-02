# frozen_string_literal: true

class Trends::StatusFilter
  KEYS = %i(
    trending
  ).freeze

  attr_reader :params

  def initialize(params)
    @params = params
  end

  def results
    scope = Status.default_scoped

    params.each do |key, value|
      next if key.to_s == 'page'

      scope.merge!(scope_for(key, value.to_s.strip)) if value.present?
    end

    scope
  end

  private

  def scope_for(key, value)
    case key.to_s
    when 'trending'
      trending_scope(value)
    else
      raise "Unknown filter: #{key}"
    end
  end

  def trending_scope(value)
    ids = begin
      case value.to_s
      when 'allowed'
        Trends.statuses.currently_trending_ids(true, -1)
      else
        Trends.statuses.currently_trending_ids(false, -1)
      end
    end

    if ids.empty?
      Status.none
    else
      Status.joins("join unnest(array[#{ids.map(&:to_i).join(',')}]::bigint[]) with ordinality as x (id, ordering) on statuses.id = x.id").order('x.ordering')
    end
  end
end

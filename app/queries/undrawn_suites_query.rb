# frozen_string_literal: true
#
# Query to return the suites that don't belong to any draw. This can bee passed
# an existing relation for a subset of all Suites.
class UndrawnSuitesQuery
  # See IntentMetricsQuery for explanation.
  class << self
    delegate :call, to: :new
  end

  # Initialize an UndrawnSuitesQuery
  #
  # @param relation [Suite::ActiveRecord_Relation] the base relation for the
  #   query
  def initialize(relation = Suite.all)
    @relation = relation
  end

  # Execute the undrawn suites query. Performs an left outer join with the
  # draws_suites table. See http://stackoverflow.com/a/31524866 for more
  # details.
  #
  # @return [Array<Suite>] the undrawn suites in the relation
  def call
    @relation.includes(:draws_suites).where(draws_suites: { suite_id: nil })
  end
end
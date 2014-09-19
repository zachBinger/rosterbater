class LeaguePolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def refresh?
    recently_updated?(user)
  end

  def show?
    true
  end

  def sync?
    recently_updated?(league)
  end

  protected

  def league
    record
  end

  def recently_updated?(object)
    logged_in? && (!object.sync_started_at || (object.sync_started_at < 10.minutes.ago))
  end
end

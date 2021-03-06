class LeaguesController < ApplicationController
  before_action :find_league, only: [:show, :weekly, :players, :draft_board, :playoffs, :parity, :charts]
  before_action :ensure_synced, only: [:weekly, :players, :draft_board, :playoffs, :parity, :charts]

  rescue_from Pundit::NotAuthorizedError, with: :please_log_in

  def index
    authorize :league, :index?
    @leagues = current_user.leagues.active
  end

  def refresh
    if current_user.currently_syncing?
      authorize :league, :index?
      redirect_to currently_refreshing_leagues_path
    else
      authorize :league, :refresh?

      YahooService.new(current_user).sync_leagues([Game.most_recent])
      # Game.all.each do |game|
      #   YahooService.new(current_user).sync_leagues(game)
      # end
      current_user.leagues.active.each do |league|
        YahooService.new(current_user).sync_league(league)
      end

      redirect_to leagues_path, notice: "Refreshed leagues"
    end
  end

  def currently_refreshing
    authorize :league, :index?
    redirect_to leagues_path if !current_user.currently_syncing?
  end

  def show
    authorize @league, :show?
  end

  def weekly
    authorize @league, :show?

    @week = (params[:week].presence || (@league.current_week - 1)).to_i
    @matchups = @league.matchups.where(week: @week)
    @matchup_stats = InterestingStatsService.by_matchup(@matchups)
    @team_stats = InterestingStatsService.by_team(@matchups.map(&:matchup_teams).flatten)
  end

  def players
    authorize @league, :show?
  end

  def sync
    league = current_user.leagues.find(params[:id])
    authorize league, :sync?
    YahooService.new(current_user).sync_league(league)

    redirect_to league_path(league), notice: "Synced league"
  end

  def draft_board
    authorize @league, :show?

    @ranking_type = params[:ranking] || case @league.points_per_reception
                                          when 1 then "ecr_ppr"
                                          when 0 then "ecr_standard"
                                          when 0.5 then "ecr_half_ppr"
                                          else "ecr_standard"
                                        end

    @teams =
      @league
        .draft_picks
        .order(auction_pick: :asc, pick: :asc)
        .each
        .with_object({}) do |draft_pick, acc|
          acc[draft_pick.team] ||= []

          info = case @ranking_type
            when "yahoo_adp"; draft_pick.yahoo_info
            when "ecr_standard"; draft_pick.ecr_standard_info
            when "ecr_ppr"; draft_pick.ecr_ppr_info
            when "ecr_half_ppr"; draft_pick.ecr_half_ppr_info
            when "position"; draft_pick.position_info
            end

          acc[draft_pick.team] << info
        end
  end

  def playoffs
    authorize @league, :show?

    @matchups = @league.matchups
    @teams = @league.teams
  end

  def parity
    authorize @league, :show?

    @matchups = @league.matchups
    @teams = @league.teams
  end

  def charts
    authorize @league, :show?

    @matchups = @league.matchups
    @teams = @league.teams
  end

  protected

  def find_league
    @league = League.find(params[:id])
  end

  def ensure_synced
    if !@league.complete?
      redirect_to league_path(@league), status: 302, notice: "Please sync this league"
    end
  end
end

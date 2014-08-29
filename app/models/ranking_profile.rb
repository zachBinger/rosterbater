class RankingProfile < ActiveRecord::Base
  belongs_to :game
  belongs_to :player, class_name: "Player", foreign_key: "yahoo_player_key", primary_key: "yahoo_player_key"
  has_many :rankings

  scope :unlinked, ->{ where(yahoo_player_key: nil) }

  def link
    if player = game.players.find_by(full_name: name)
      update(player: player)
    elsif rankings.map(&:position).include?("DST")
      player = game.players.find_by(display_position: "DEF", editorial_team_full_name: name)

      update(player: player)
    end
  end
end

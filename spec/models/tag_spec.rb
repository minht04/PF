require 'rails_helper'

RSpec.describe 'Tagモデルのテスト', type: :model do
  describe 'アソシエーションのテスト' do
    context 'Tag_mapモデルとの関係' do
      it '1:Nの関係になっている' do
        expect(Tag.reflect_on_association(:tag_maps).macro).to eq :has_many
      end
    end

    context 'Postモデルとの関係' do
      it '1:Nの関係になっている' do
        expect(Tag.reflect_on_association(:posts).macro).to eq :has_many
      end
    end
  end

end
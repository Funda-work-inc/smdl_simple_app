require 'rails_helper'

RSpec.describe SimpleTransactionItem, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      item = build(:simple_transaction_item)
      expect(item).to be_valid
    end

    describe 'item_name' do
      it 'item_nameが存在しない場合、無効であること' do
        item = build(:simple_transaction_item, item_name: nil)
        expect(item).to be_invalid
        expect(item.errors[:item_name]).to include("can't be blank")
      end

      it 'item_nameが255文字を超える場合、無効であること' do
        item = build(:simple_transaction_item, item_name: 'a' * 256)
        expect(item).to be_invalid
        expect(item.errors[:item_name]).to include("is too long (maximum is 255 characters)")
      end

      it 'item_nameが255文字以下の場合、有効であること' do
        item = build(:simple_transaction_item, item_name: 'a' * 255)
        expect(item).to be_valid
      end
    end

    describe 'item_count' do
      it 'item_countが存在しない場合、無効であること' do
        item = build(:simple_transaction_item, item_count: nil)
        expect(item).to be_invalid
        expect(item.errors[:item_count]).to include("can't be blank")
      end

      it 'item_countが0以下の場合、無効であること' do
        item = build(:simple_transaction_item, item_count: 0)
        expect(item).to be_invalid
        expect(item.errors[:item_count]).to include("must be greater than 0")
      end

      it 'item_countが99999を超える場合、無効であること' do
        item = build(:simple_transaction_item, item_count: 100000)
        expect(item).to be_invalid
        expect(item.errors[:item_count]).to include("must be less than or equal to 99999")
      end

      it 'item_countが1以上99999以下の場合、有効であること' do
        item = build(:simple_transaction_item, item_count: 99999)
        expect(item).to be_valid
      end
    end

    describe 'item_price' do
      it 'item_priceが存在しない場合、無効であること' do
        item = build(:simple_transaction_item, item_price: nil)
        expect(item).to be_invalid
        expect(item.errors[:item_price]).to include("can't be blank")
      end

      it 'item_priceが0以下の場合、無効であること' do
        item = build(:simple_transaction_item, item_price: 0)
        expect(item).to be_invalid
        expect(item.errors[:item_price]).to include("must be greater than 0")
      end

      it 'item_priceが1以上の場合、有効であること' do
        item = build(:simple_transaction_item, item_price: 1)
        expect(item).to be_valid
      end
    end

    describe 'simple_transaction' do
      it 'simple_transactionが存在しない場合、無効であること' do
        item = build(:simple_transaction_item, simple_transaction: nil)
        expect(item).to be_invalid
        expect(item.errors[:simple_transaction]).to include("must exist")
      end
    end
  end

  describe 'リレーション' do
    it 'simple_transactionに属していること' do
      association = described_class.reflect_on_association(:simple_transaction)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end

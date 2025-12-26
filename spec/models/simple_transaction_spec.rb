require 'rails_helper'

RSpec.describe SimpleTransaction, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      transaction = build(:simple_transaction)
      expect(transaction).to be_valid
    end

    describe 'amount' do
      it 'amountが存在しない場合、無効であること' do
        transaction = build(:simple_transaction, amount: nil)
        expect(transaction).to be_invalid
        expect(transaction.errors[:amount]).to include("can't be blank")
      end

      it 'amountが0以下の場合、無効であること' do
        transaction = build(:simple_transaction, amount: 0)
        expect(transaction).to be_invalid
        expect(transaction.errors[:amount]).to include("must be greater than 0")
      end

      it 'amountが1以上の場合、有効であること' do
        transaction = build(:simple_transaction, amount: 1)
        expect(transaction).to be_valid
      end
    end

    describe 'registration_datetime' do
      it 'registration_datetimeが存在しない場合、無効であること' do
        transaction = build(:simple_transaction, registration_datetime: nil)
        expect(transaction).to be_invalid
        expect(transaction.errors[:registration_datetime]).to include("can't be blank")
      end
    end

    describe 'status' do
      it 'statusが存在しない場合、無効であること' do
        transaction = build(:simple_transaction, status: nil)
        expect(transaction).to be_invalid
        expect(transaction.errors[:status]).to include("can't be blank")
      end

      it 'statusが許可された値（active, cancelled, deleted）の場合、有効であること' do
        %w[active cancelled deleted].each do |status_value|
          transaction = build(:simple_transaction, status: status_value)
          expect(transaction).to be_valid
        end
      end

      it 'statusが許可されていない値の場合、無効であること' do
        transaction = build(:simple_transaction, status: 'invalid_status')
        expect(transaction).to be_invalid
        expect(transaction.errors[:status]).to include("is not included in the list")
      end
    end
  end
end

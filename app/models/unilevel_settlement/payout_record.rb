module UnilevelSettlement
  class PayoutRecord < ApplicationRecord
    belongs_to :invoice, class_name: 'UnilevelSettlement::PayoutInvoice', foreign_key: 'unilevel_settlement_payout_invoice_id',
                         optional: false, inverse_of: :records
    belongs_to :contract, class_name: 'UnilevelSettlement::Contract', foreign_key: 'unilevel_settlement_contract_id',
                          optional: false, inverse_of: :records

    has_one :user, through: :invoice

    def assign_attributes_from_contract
      self.amount = calculate_amount
      self.vat = calculate_vat if pays_vat?
      self
    end

    private

    def calculate_amount
      return 0 if contract.rejected?

      provision = contract.provider.provision_for_level(level)
      contract.cancellation? ? provision * -1 : provision
    end

    def pays_vat?
      pays_vat = invoice.user.send(UnilevelSettlement.vat)
      case pays_vat
      when true, 'true', 'TRUE', 1, '1' then true
      when false, 'false', 'FALSE', 0, '0' then false
      end
    end

    def calculate_vat
      vat_proportion = if UnilevelSettlement.vat.zero?
                         0
                       elsif UnilevelSettlement.vat < 1
                         UnilevelSettlement.vat
                       elsif UnilevelSettlement.vat > 1
                         UnilevelSettlement.vat.fdiv(100)
                       end
      amount * vat_proportion
    end
  end
end

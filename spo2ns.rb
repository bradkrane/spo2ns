# idea to ruby spo2ns <strftime fmt str> <shopify 'bank' acct> <fees acct> <po exports.csv>
FILE = 'shopify payouts ENTIRE history to March 4 2022.csv' #String (ARGV.pop)
FEES = '69160'#Integer(ARGV.pop)
SHOP = '11080'#Integer(ARGV.pop)
BANK = '11030'
DFMT = '%d-%b-%y'#String (ARGV.pop)

EXPECTED_HEADER = ["Payout Date", "Status", "Charges", "Refunds", "Adjustments", "Reserved Funds", "Fees", "Retried Amount", "Total", "Currency"]

require 'csv'
# file = ARGV.pop
data = File.open('shopify payouts ENTIRE history to March 4 2022.csv') { |f| CSV.parse(f) }
HEADER = data.shift

# if data is not as expected throw unhandled exception to crash and burn
raise "Unexpected CSV header should equal : '#{EXPECTED_HEADER}'" if HEADER != EXPECTED_HEADER

class StatusException < ArgumentError
  def self.STATUSES
    ['paid','failed','in_transit']
  end
  def self.valid_status? status
    status == StatusException.STATUSES.first
  end
end

require 'date'
# SPO  aka Shopify Payout
class SPORow
  @@datefmt = '%Y-%m-%d'
  def self.datefmt= datefmt; @@datefmt = datefmt; end
  def self.datefmt; @@datefmt; end

  def initialize data
    # Same order as EXPECTED_HEADER
    @date           = Date.parse data.shift
    if !StatusException.valid_status?(@status = data.shift)
      raise StatusException.new "Invalid status '#{@status}' must be one of: '#{StatusException.STATUSES}'" 
    end
    @charges        = data.shift.to_f
    @refunds        = data.shift.to_f
    @adjustments    = data.shift.to_f
    @reserved_funds = data.shift.to_f
    @fees           = data.shift.to_f
    @retried_amount = data.shift.to_f
    @total          = data.shift.to_f
    #raise RangeError.new 'No code for negative Shopify payouts' if @total < 0 # even possible?
    @currency       = String(data.shift) == 'CAD' ? 1 : 2 # CAD as primary currency IID == 1
  end
  attr_reader :status, :charges, :refunds, :adjustments, :reserved_funds, :fees, :retried_amount, :total, :currency
  def date
    @date.strftime @@datefmt
  end
  def has_refund?
    refunds != 0
  end
end

SPORow.datefmt = DFMT
mapped = data.map { |line| 
  begin
    SPORow.new line
  rescue => e
    throw e if e.class != StatusException
    nil
  end
}

print CSV.generate { |csv|
  mapped.each { |po|
    next if po == nil

    # output the GL import lines for the payment to the bank from the Shopify account
    # and the fees to the Expense account from the Shopify acct
    # Debit Bank Total and Credit Shopify Bank total
    # Debit Fees Expense > Credit Shopify Bank fees
    csv << ['Date', 'Account', 'Credit', 'Debit', 'Memo']
    def gl_entry date, credit, debit, amount, memo
      [[date, credit, amount, 0, memo],
       [date, debit,  0, amount, memo]]
    end
    csv << gl_entry(po.date, SHOP, BANK, po.total, "Shopify Payout to Bank #{po.date}." )
    csv << gl_entry(po.date, SHOP, FEES, po.total, "Shopify Fees Expense #{po.date}.")
    
    next unless po.has_refund?
    # reverse the fee by adjustment amount
    csv << gl_entry(po.date, FEES, SHOP, po.adjustments, "Fees adjustments for customer refunds #{po.date}.")
  }
}

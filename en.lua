Locales = {}

Locales['en'] = {
    -- Interaction
    ['open_menu'] = 'Press ~g~[E]~s~ to talk to the ~b~Loan Officer~s~',
    ['enter_amount'] = 'Enter amount',
    ['loan_menu'] = 'Bank Loans',
    ['take_loan'] = 'Request Loan',
    ['repay_loan'] = 'Repay Loan',
    ['check_status'] = 'Check Loan Status',
    ['close'] = 'Close',

    -- Notifications
    ['invalid_loan_amount'] = 'Invalid loan amount.',
    ['already_has_loan'] = 'You already have an active loan.',
    ['loan_create_failed'] = 'Could not create a new loan.',
    ['loan_granted'] = 'Loan granted: %s%s.',
    ['loan_granted_but_bank_update_failed'] = 'Loan granted, but bank account failed to update.',
    ['invalid_repayment_amount'] = 'Invalid repayment amount.',
    ['no_active_loan'] = 'You have no active loan.',
    ['insufficient_funds'] = 'Insufficient funds in bank.',
    ['repayment_failed'] = 'Repayment failed.',
    ['loan_fully_paid'] = 'You fully repaid your loan. Thank you!',
    ['payment_success_remaining'] = 'Payment complete. Remaining debt: %s%s.',
    ['status_none'] = 'You have no active loan.',
    ['status_active'] = 'Loan: Principal %s%s | Rate %s%% | Total %s%s | Paid %s%s | Remaining %s%s',

    -- Commands (client extras)
    ['cmd_loan_hint'] = 'Usage: /loan [amount]',
    ['cmd_pay_hint']  = 'Usage: /payloan [amount]',
}

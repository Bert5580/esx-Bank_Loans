local Translations = {
    ui = {
        open_menu   = 'Press ~INPUT_CONTEXT~ to speak with Loan Officer',
        loan_menu   = 'Bank Loans',
        apply_loan  = 'Apply for Loan',
        pay_loan    = 'Make a Payment',
        view_loans  = 'View Active Loans',
        close       = 'Close',
    },
    notify = {
        not_enough_credit = 'Your credit score is too low to borrow. (min %{min})',
        too_many_loans    = 'You already have too many active loans.',
        amount_invalid    = 'Invalid amount.',
        interest_invalid  = 'Interest rate is invalid.',
        loan_created      = 'Loan approved for $%{amount} (APR %{apr}%).',
        payment_ok        = 'Payment of $%{amount} received. Remaining debt: $%{remain}.',
        no_debt           = 'You have no outstanding debt.',
        not_enough_cash   = 'Insufficient funds.',
        admin_only        = 'You do not have permission.',
        use_command_apply = 'Type /apply_loan [amount] to submit a loan request.',
        overpay_applied   = 'Overpayment of $%{extra} applied to next loan(s).',
    },
    cmd = {
        grant   = 'Grant a loan to player',
        pay     = 'Pay part of a loan',
        credit  = 'Adjust player credit',
        apply   = 'Apply for a loan amount',
        loans   = 'List your active loans',
        forgive = 'Admin: forgive (write off) a loan by ID',
        setrate = 'Admin: set APR on a loan by ID'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

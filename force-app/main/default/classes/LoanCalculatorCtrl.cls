public with sharing class LoanCalculatorCtrl {
    
    public class LoanDetails {
        @AuraEnabled public Decimal purchasePrice {get; set;}
        @AuraEnabled public Decimal deposit {get; set;}
        @AuraEnabled public Decimal loanAmount {get; set;}
        @AuraEnabled public Boolean lenderFeeFinanced {get; set;}
        @AuraEnabled public Decimal lenderFee {get; set;}
        @AuraEnabled public Decimal amountFinancedLenderFee {get; set;}
        @AuraEnabled public Boolean otherFeesChargesFinanced {get; set;}
        @AuraEnabled public Decimal otherFeesCharges {get; set;}
        @AuraEnabled public Decimal netAmountFinanced {get; set;}
        @AuraEnabled public String balloonType {get; set;}
        @AuraEnabled public Decimal balloonValueValue {get; set;}
        @AuraEnabled public Decimal balloonValuePercentage {get; set;}
        @AuraEnabled public Decimal balloonAmount {get; set;}
        @AuraEnabled public Boolean gstRecoup {get; set;}
        @AuraEnabled public Decimal gstAmount {get; set;}
        @AuraEnabled public Integer gstRecoupInstalment {get; set;}
        @AuraEnabled public Decimal accountKeepingFee {get; set;}
        @AuraEnabled public String repaymentStructure {get; set;}
        @AuraEnabled public String repaymentFrequency {get; set;}
        @AuraEnabled public Integer numberOfInstalments {get; set;}
        @AuraEnabled public Date loanStartDate {get; set;}
        @AuraEnabled public Date firstRepaymentDueDate {get; set;}
        @AuraEnabled public Date loanEndDate {get; set;}
        @AuraEnabled public Decimal interestRate {get; set;}
        @AuraEnabled public Decimal scheduleRepayment {get; set;}
        @AuraEnabled public Decimal totalAdditionalRepayments {get; set;}
        @AuraEnabled public Decimal totalInterestCharges {get; set;}
        @AuraEnabled public Decimal totalAmountToBePaid {get; set;}
        @AuraEnabled public List<InstalmentInfo> instalments {get; set;}
    }
    
    public class InstalmentInfo {
        @AuraEnabled public Integer instalmentNo {get; set;}
        @AuraEnabled public Date instalmentDate {get; set;}
        @AuraEnabled public Decimal openingPrincipal {get; set;}
        @AuraEnabled public Decimal openingBalance {get; set;}
        @AuraEnabled public Decimal additionalRepayments {get; set;}
        @AuraEnabled public Decimal repayment {get; set;}
        @AuraEnabled public Decimal interest {get; set;}
        @AuraEnabled public Decimal principle {get; set;}
        @AuraEnabled public Decimal closingPrincipal {get; set;}
        @AuraEnabled public Decimal closingBalance {get; set;}
    }
    
    public class LoanDetailsByComparison {
        @AuraEnabled public LoanDetails loan {get; set;}
        @AuraEnabled public List<LoanDetails> loans {get; set;}
    }
    
    @AuraEnabled
    public static Map<String, Object> calculateLoanDetailsByComparison(String loanDetailsStr) {
        
        Map<String, Object> result = new Map<String, Object>();
        List<Integer> numberOfInstalmentsOptions = new List<Integer>{60, 48, 36, 24, 12};
            List<Integer> balloonAmountPercentageOptions = new List<Integer>{30, 20, 10, 0};
                
                LoanDetails loan = (LoanDetails) JSON.deserialize(loanDetailsStr, LoanDetails.Class);
        List<LoanDetailsByComparison> loansByComparisonNumberOfInstalments = new List<LoanDetailsByComparison>();
        List<LoanDetailsByComparison> loansByComparisonBalloonAmountPercentage = new List<LoanDetailsByComparison>();
        
        for(Integer numberOfInstalments : numberOfInstalmentsOptions) {
            
            LoanDetailsByComparison loanByComparison = new LoanDetailsByComparison();
            LoanDetails tempLoan = loan.clone();
            
            tempLoan.numberOfInstalments = numberOfInstalments;
            
            loanByComparison.loan = calculateLoanDetails(JSON.serialize(tempLoan), false);
            
            List<LoanDetails> loans = new List<LoanDetails>();
            
            for(Integer balloonAmountPercentage : balloonAmountPercentageOptions) {
                
                tempLoan.balloonType = 'Percentage (By Loan Amount)';
                tempLoan.balloonValuePercentage = balloonAmountPercentage;
                
                loans.add(calculateLoanDetails(JSON.serialize(tempLoan), false));                 
            }
            
            loanByComparison.loans = loans;
            
            loansByComparisonNumberOfInstalments.add(loanByComparison);
        }
        
        for(Integer balloonAmountPercentage : balloonAmountPercentageOptions) {
            
            LoanDetailsByComparison loanByComparison = new LoanDetailsByComparison();
            LoanDetails tempLoan = loan.clone();
            
            tempLoan.balloonType = 'Percentage (By Loan Amount)';
            tempLoan.balloonValuePercentage = balloonAmountPercentage;
            
            loanByComparison.loan = calculateLoanDetails(JSON.serialize(tempLoan), false);
            
            List<LoanDetails> loans = new List<LoanDetails>();
            
            for(Integer numberOfInstalments : numberOfInstalmentsOptions) {
                
                tempLoan.numberOfInstalments = numberOfInstalments;
                
                loans.add(calculateLoanDetails(JSON.serialize(tempLoan), false));                 
            }
            
            loanByComparison.loans = loans;
            
            loansByComparisonBalloonAmountPercentage.add(loanByComparison);
        }
        
        result.put('loanDetails', calculateLoanDetails(JSON.serialize(loan), true));
        result.put('loansByComparisonNumberOfInstalments', loansByComparisonNumberOfInstalments);
        result.put('loansByComparisonBalloonAmountPercentage', loansByComparisonBalloonAmountPercentage);
        
        return result;
    }
    
    @AuraEnabled
    public static LoanDetails calculateLoanDetails(String loanDetailsStr, Boolean addInstalments) {
        
        LoanDetails loan = (LoanDetails) JSON.deserialize(loanDetailsStr, LoanDetails.Class);
        
        if(loan.purchasePrice == null) {
            loan.purchasePrice = 0;
        }
        
        if(loan.deposit == null) {
            loan.deposit = 0;
        }
        
        loan.balloonAmount = 0;
        
        if(loan.gstAmount == null) {
            loan.gstAmount = 0;
        }
        
        if(loan.gstRecoupInstalment == null) {
            loan.gstRecoupInstalment = 0;
        }
        
        loan.loanAmount = loan.purchasePrice - loan.deposit;
        
        loan.amountFinancedLenderFee = loan.loanAmount;
        
        if(loan.lenderFeeFinanced) {
            loan.amountFinancedLenderFee += loan.lenderFee;
        }
        
        loan.netAmountFinanced = loan.amountFinancedLenderFee;
        
        if(loan.otherFeesChargesFinanced) {
            loan.netAmountFinanced += loan.otherFeesCharges;
        }
        
        if(loan.balloonType == 'Value') {
            loan.balloonAmount = loan.balloonValueValue;
        }
        
        if(loan.balloonType == 'Percentage (By Loan Amount)') {
            loan.balloonAmount = (loan.loanAmount * loan.balloonValuePercentage) / 100;
        }
        
        if(loan.balloonType == 'Percentage (By Net Amount Financed)') {
            loan.balloonAmount = (loan.netAmountFinanced * loan.balloonValuePercentage) / 100;
        }
        
        Integer numberOfPaymentsPerYear = loan.repaymentFrequency == 'Monthly'
            ? 12
            : loan.repaymentFrequency == 'Fortnightly'
                ? 26
                : loan.repaymentFrequency == 'Weekly'
                    ? 52
                    : 0;
        
        loan.firstRepaymentDueDate = loan.repaymentStructure == 'Advance'    
            ? loan.loanStartDate
            : loan.repaymentFrequency == 'Monthly' 
                ? loan.loanStartDate.addMonths(1) 
                : loan.repaymentFrequency == 'Fortnightly' 
                    ? loan.loanStartDate.addDays(14) 
                    : loan.repaymentFrequency == 'Weekly' 
                        ? loan.loanStartDate.addDays(7) 
                        : null; 
        
        loan.loanEndDate = loan.repaymentFrequency == 'Monthly' 
            ? loan.firstRepaymentDueDate.addMonths(loan.numberOfInstalments  - 1) 
            : loan.repaymentFrequency == 'Fortnightly' ? loan.firstRepaymentDueDate.addDays((loan.numberOfInstalments  - 1) * 14) : 
        loan.repaymentFrequency == 'Weekly' ? loan.firstRepaymentDueDate.addDays((loan.numberOfInstalments  - 1) * 7) : null;
        
        Decimal interestRateByRepaymentFrequency = loan.interestRate / numberOfPaymentsPerYear;
        
        Decimal netAmountFinancedForScheduleRepayment = loan.balloonAmount != null 
            ? loan.repaymentStructure == 'Advance'
            ? loan.netAmountFinanced - (loan.balloonAmount / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments - 1))) - (loan.gstAmount / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), Integer.valueOf(loan.gstRecoupInstalment) - 1)))
            : loan.netAmountFinanced - (loan.balloonAmount / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments))) - (loan.gstAmount / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), Integer.valueOf(loan.gstRecoupInstalment))))
                : loan.netAmountFinanced;
        
        loan.scheduleRepayment = loan.repaymentStructure == 'Advance' 
            ? ((netAmountFinancedForScheduleRepayment * (interestRateByRepaymentFrequency / 100) * Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments - 1)) / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments) - 1)).setScale(2, RoundingMode.HALF_UP)
            : ((netAmountFinancedForScheduleRepayment * (interestRateByRepaymentFrequency / 100) * Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments)) / (Math.pow(Double.valueOf(1 + (interestRateByRepaymentFrequency / 100)), loan.numberOfInstalments) - 1)).setScale(2, RoundingMode.HALF_UP);         
        
        List<InstalmentInfo> instalments = new List<InstalmentInfo>();
        Decimal openingPrincipal = loan.netAmountFinanced;
        
        for(Integer i = 1; i <= loan.numberOfInstalments; i++) {
            
            InstalmentInfo instalment = new InstalmentInfo();
            instalment.instalmentNo = i;
            
            switch on loan.repaymentFrequency {
                when 'Monthly' {
                    instalment.instalmentDate = loan.firstRepaymentDueDate.addMonths(i - 1);
                }
                
                when 'Fortnightly' {
                    instalment.instalmentDate = loan.firstRepaymentDueDate.addDays((i - 1) * 14);
                }
                
                when 'Weekly' {
                    instalment.instalmentDate = loan.firstRepaymentDueDate.addDays(7 * (i - 1));
                }
                
                when else {	
                    instalment.instalmentDate = null;
                }
            }
            
            instalment.openingPrincipal = openingPrincipal;
            
            instalment.additionalRepayments = loan.gstRecoup && i == loan.gstRecoupInstalment  && loan.gstAmount != null
                ? loan.gstAmount
                : i == loan.numberOfInstalments && loan.balloonAmount != null
                    ? loan.balloonAmount
                    : 0;
            instalment.repayment = loan.scheduleRepayment;
            instalment.interest =  i == 1 && loan.repaymentStructure == 'Advance' 
                ? 0 
                : ((openingPrincipal * interestRateByRepaymentFrequency) / 100).setScale(2, RoundingMode.HALF_UP);
            instalment.principle = instalment.repayment - instalment.interest;
            instalment.closingPrincipal = i == loan.numberOfInstalments
                ? 0
                : instalment.openingPrincipal - instalment.principle - instalment.additionalRepayments;
            
            instalments.add(instalment);
            
            openingPrincipal = instalment.closingPrincipal;
        }
        
        loan.totalAdditionalRepayments = 0;
        loan.totalInterestCharges = 0;
        
        for(InstalmentInfo instalment : instalments) {
            loan.totalAdditionalRepayments += instalment.additionalRepayments;
            loan.totalInterestCharges += instalment.interest;
        }
        
        loan.totalAmountToBePaid = loan.netAmountFinanced + loan.totalInterestCharges;
        
        Decimal openingBalance = loan.totalAmountToBePaid;
        
        for(InstalmentInfo instalment : instalments) {
            instalment.openingBalance = openingBalance;
            instalment.closingBalance = instalment.openingBalance - (instalment.additionalRepayments + instalment.repayment);
            
            openingBalance = instalment.closingBalance;
        }
        
        instalments[loan.numberOfInstalments - 1].closingBalance = 0;
        
        if(addInstalments) {
            loan.instalments = instalments;
        }
        
        return loan;
    }
}
public with sharing class LoanCalculatorPdfCtrl {
    
    public LoanCalculatorCtrl.LoanDetails loanDetails {get; set;}
    public List<LoanCalculatorCtrl.LoanDetailsByComparison> loansByComparisonNumberOfInstalments {get; set;}
    public List<LoanCalculatorCtrl.LoanDetailsByComparison> loansByComparisonBalloonAmountPercentage {get; set;}

    public LoanCalculatorPdfCtrl() {
        
        String loanDetailsStr = ApexPages.currentPage().getParameters().get('loanDetailsStr');
        
        Map<String, Object> result = LoanCalculatorCtrl.calculateLoanDetailsByComparison(loanDetailsStr);
        
        loanDetails = (LoanCalculatorCtrl.LoanDetails) result.get('loanDetails');
        loansByComparisonNumberOfInstalments = (List<LoanCalculatorCtrl.LoanDetailsByComparison>) result.get('loansByComparisonNumberOfInstalments');
        loansByComparisonBalloonAmountPercentage = (List<LoanCalculatorCtrl.LoanDetailsByComparison>) result.get('loansByComparisonBalloonAmountPercentage');
    }
}
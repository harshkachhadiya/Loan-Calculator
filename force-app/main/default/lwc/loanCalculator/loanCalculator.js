import { LightningElement, track } from 'lwc';
import { dispatchToastGeneralError, dispatchToastError, formatDateToYYYYMMDD, formatString, formatCurrency, copyToClipboard } from 'c/sharedUtils';
import calculateLoanDetailsByComparison from '@salesforce/apex/LoanCalculatorCtrl.calculateLoanDetailsByComparison';

export default class LoanCalculator extends LightningElement {

    @track loan = {};
    @track instalments = [];
    @track loansByComparisonNumberOfInstalments = [];
    @track loansByComparisonBalloonAmountPercentage = [];

    activeSections = [
        'A',
        'B'
    ];
    balloonTypeOptions = [
        {
            label: '--None--',
            value: null
        },
        {
            label: 'Value',
            value: 'Value'
        },
        {
            label: 'Percentage (By Loan Amount)',
            value: 'Percentage (By Loan Amount)'
        },
        {
            label: 'Percentage (By Net Amount Financed)',
            value: 'Percentage (By Net Amount Financed)'
        }
    ];
    repaymentStructureOptions = [
        {
            label: '--None--',
            value: null
        },
        {
            label: 'Advance',
            value: 'Advance'
        },
        {
            label: 'Arrears',
            value: 'Arrears'
        }
    ];
    repaymentFrequencyOptions = [
        {
            label: '--None--',
            value: null
        },
        {
            label: 'Monthly',
            value: 'Monthly'
        },
        {
            label: 'Fortnightly',
            value: 'Fortnightly'
        },
        {
            label: 'Weekly',
            value: 'Weekly'
        }
    ];
    columns = [
        {
            label: 'Instalment No',
            fieldName: 'instalmentNo',
            type: 'number'
        },
        {
            label: 'Instalment Date',
            fieldName: 'instalmentDate',
            type: 'date'
        },
        {
            label: 'Opening Balance',
            fieldName: 'openingBalance',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        },
        {
            label: 'GST Payment / Balloon Payment / Additional Repayments',
            fieldName: 'additionalRepayments',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        },
        {
            label: 'Repayment',
            fieldName: 'repayment',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        },
        {
            label: 'Interest',
            fieldName: 'interest',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        },
        {
            label: 'Principle',
            fieldName: 'principle',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        },
        {
            label: 'Closing Balance',
            fieldName: 'closingBalance',
            type: 'currency',
            typeAttributes: {
                currencyDisplayAs: 'symbol',
                step: '0.01'
            }
        }
    ];
    showBalloonValueValue = false;
    showBalloonValuePercentage = false;
    documentUrl;
    isGenerateDocumentsModalOpen = false;
    isLoading = false;

    connectedCallback() {
        this.loan.purchasePrice = 100000;
        this.loan.deposit = 0;
        this.loan.loanAmount = null;
        this.loan.lenderFeeFinanced = false;
        this.loan.lenderFee = 0;
        this.loan.amountFinancedLenderFee = null;
        this.loan.otherFeesChargesFinanced = false;
        this.loan.otherFeesCharges = null;
        this.loan.netAmountFinanced = null;
        this.loan.balloonType = null;
        this.loan.balloonValueValue = null;
        this.loan.balloonValuePercentage = null;
        this.loan.balloonAmount = null;
        this.loan.gstRecoup = false;
        this.loan.gstAmount = null;
        this.loan.gstRecoupInstalment = null;
        this.loan.accountKeepingFee = 0;
        this.loan.repaymentStructure = 'Advance';
        this.loan.repaymentFrequency = 'Monthly';
        this.loan.numberOfInstalments = 60;
        this.loan.loanStartDate = formatDateToYYYYMMDD(new Date());
        this.loan.firstRepaymentDueDate = null;
        this.loan.loanEndDate = null;
        this.loan.interestRate = 8;
        this.loan.scheduleRepayment = null;
        this.loan.additionalRepayments = null;
        this.loan.totalInterestCharges = null;
        this.loan.totalAmountToBePaid = null;

        this.calculateLoanDetails();
    }

    renderedCallback() {
        const style = document.createElement('style');

        style.innerText = `
            .loan-calculator-container button.slds-accordion__summary-action {
                background: rgb(243, 243, 243);
            }

            .loan-calculator-container input.slds-input,
            .loan-calculator-container button.slds-combobox__input {
                
            }
           `;

        this.template.querySelector('.loan-calculator-container').appendChild(style);
    }

    handleChangeInput(event) {
        let dataName = event.target.dataset.name;
        let value = event.detail.value ? event.detail.value : null;

        switch (dataName) {
            case 'purchasePrice':
            case 'deposit':
            case 'lenderFee':
            case 'otherFeesCharges':
            case 'balloonValueValue':
            case 'balloonValuePercentage':
            case 'gstAmount':
            case 'gstAmount':
            case 'accountKeepingFee':
                this.loan[dataName] = parseFloat(value);
                break;

            case 'lenderFeeFinanced':
            case 'otherFeesChargesFinanced':
            case 'gstRecoup':
                this.loan[dataName] = event.detail.checked;
                break;

            case 'gstRecoupInstalment':
            case 'numberOfInstalments':
                this.loan[dataName] = parseInt(value);
                break;

            default:
                this.loan[dataName] = value;
        }

        if (!this.loan.otherFeesChargesFinanced) {
            this.loan.otherFeesCharges = null;
        }

        this.showBalloonValueValue = this.loan.balloonType == 'Value';
        this.showBalloonValuePercentage = this.loan.balloonType == 'Percentage (By Loan Amount)' || this.loan.balloonType == 'Percentage (By Net Amount Financed)';
        this.showBallonAmount = this.showBalloonValueValue || this.showBalloonValuePercentage;

        if (!this.showBalloonValueValue) {
            this.loan.balloonValueValue = null;
        }

        if (!this.showBalloonValuePercentage) {
            this.loan.balloonValuePercentage = null;
        }

        if (!this.loan.gstRecoup) {
            this.loan.gstAmount = null;
            this.loan.gstRecoupInstalment = null;
        }

        setTimeout(() => {
            this.calculateLoanDetails();
        }, 100);
    }

    calculateLoanDetails() {
        if (!this.checkInputsValidity()) {
            return;
        }

        this.isLoading = true;
        this.instalments = [];
        this.loansByComparisonNumberOfInstalments = [];
        this.loansByComparisonBalloonAmountPercentage = [];

        calculateLoanDetailsByComparison({
            loanDetailsStr: JSON.stringify(this.loan)
        })
            .then((result) => {
                // console.log('result--', JSON.stringify(result));

                if (result && Object.keys(result).length) {

                    Object.keys(result.loanDetails).forEach((item) => {
                        this.loan[item] = result.loanDetails[item];
                    });
                }

                this.instalments = result.loanDetails.instalments;
                this.loansByComparisonNumberOfInstalments = result.loansByComparisonNumberOfInstalments;
                this.loansByComparisonBalloonAmountPercentage = result.loansByComparisonBalloonAmountPercentage;
            })
            .catch((error) => {
                dispatchToastError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleClickCopyDetails() {
        if (!this.checkInputsValidity()) {
            return;
        }

        let copyText = '*Loan Details*\n'
            + '\n Purchase Price: ' + formatCurrency(this.loan.purchasePrice);

        copyToClipboard(copyText);
    }

    handleClickGenerateDocuments() {
        if (!this.checkInputsValidity()) {
            return;
        }

        let loan = Object.assign({}, this.loan);
        loan.instalments = null;

        this.documentUrl = '/apex/LoanCalculatorPdf?loanDetailsStr=' + JSON.stringify(loan);

        this.openGenerateDocumentsModal();
    }

    handleClickCopyComparisonDetailsByNumberOfInstalments(event) {
        const loanByComparision = this.loansByComparisonNumberOfInstalments.find((item) => item.loan.numberOfInstalments == parseInt(event.target.dataset.numberofinstalments));

        if (loanByComparision) {

            let copyText = '*Loan Comparison Details for Loan Term ' + formatString(loanByComparision.loan.numberOfInstalments) + ' Months*';

            copyText += '\n\n Purchase Price: ' + formatCurrency(loanByComparision.loan.purchasePrice)
                + '\n Deposit/Trade In: ' + formatCurrency(loanByComparision.loan.deposit)
                + '\n Loan Amount: ' + formatCurrency(loanByComparision.loan.loanAmount);

            loanByComparision.loans.forEach((loan) => {
                copyText += '\n\nBalloon Value (Percentage): ' + formatString(loan.balloonValuePercentage) + ' %'
                    + '\n Balloon Amount: ' + formatCurrency(loan.balloonAmount)
                    + '\n Schedule Repayment: ' + formatCurrency(loan.scheduleRepayment)
                    + '\n Estimated Total Interest Charges: ' + formatCurrency(loan.totalInterestCharges)
                    + '\n Estimated Principal And Interest To Be Paid Over The Term Of The Loan: ' + formatCurrency(loan.totalAmountToBePaid);
            });

            copyToClipboard(copyText);

        } else {
            dispatchToastGeneralError();
        }
    }

    handleClickCopyComparisonDetailsByBalloonAmount(event) {
        const loanByComparision = this.loansByComparisonBalloonAmountPercentage.find((item) => item.loan.balloonValuePercentage == parseFloat(event.target.dataset.balloonvaluepercentage));

        if (loanByComparision) {

            let copyText = '*Loan Comparison Details for Balloon Percentage: ' + formatString(loanByComparision.loan.balloonValuePercentage) + '% / Balloon Amount: ' + formatCurrency(loanByComparision.loan.balloonAmount);

            copyText += '\n\n Purchase Price: ' + formatCurrency(loanByComparision.loan.purchasePrice)
                + '\n Deposit/Trade In: ' + formatCurrency(loanByComparision.loan.deposit)
                + '\n Loan Amount: ' + formatCurrency(loanByComparision.loan.loanAmount);

            loanByComparision.loans.forEach((loan) => {
                copyText += '\n\nLoan Term: ' + formatString(loan.numberOfInstalments) + ' Months'
                    + '\n Schedule Repayment: ' + formatCurrency(loan.scheduleRepayment)
                    + '\n Estimated Total Interest Charges: ' + formatCurrency(loan.totalInterestCharges)
                    + '\n Estimated Principal And Interest To Be Paid Over The Term Of The Loan: ' + formatCurrency(loan.totalAmountToBePaid);
            });

            copyToClipboard(copyText);

        } else {
            dispatchToastGeneralError();
        }
    }

    openGenerateDocumentsModal() {
        this.isGenerateDocumentsModalOpen = true;
    }

    closeGenerateDocumentsModal() {
        this.isGenerateDocumentsModalOpen = false;
    }

    checkInputsValidity() {
        return [...this.template.querySelectorAll('lightning-input, lightning-combobox')].reduce((validSoFar, field) => {
            return (field.reportValidity() && validSoFar);
        }, true);
    }
}
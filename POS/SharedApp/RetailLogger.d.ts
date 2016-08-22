/**
 * SAMPLE CODE NOTICE
 * 
 * THIS SAMPLE CODE IS MADE AVAILABLE AS IS.  MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
 * OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
 * THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
 * NO TECHNICAL SUPPORT IS PROVIDED.  YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
 */

/// <reference path="Diagnostics.TypeScriptCore.d.ts" />
import TsLogging = Microsoft.Dynamics.Diagnostics.TypeScriptCore;
declare module Commerce {
    function attachLoggingSink(sink: TsLogging.ILoggingSink): void;
    class RetailLogger {
        static writePageViewEvent(pageName: string): void;
        static genericError(message: string): void;
        static genericWarning(message: string): void;
        static genericInfo(message: string): void;
        static extendedCritical(message: string, parameter1?: string, parameter2?: string, parameter3?: string, parameter4?: string, parameter5?: string, parmater6?: string): void;
        static extendedError(message: string, parameter1?: string, parameter2?: string, parameter3?: string, parameter4?: string, parameter5?: string, parmater6?: string): void;
        static extendedWarning(message: string, parameter1?: string, parameter2?: string, parameter3?: string, parameter4?: string, parameter5?: string, parmater6?: string): void;
        static extendedInformational(message: string, parameter1?: string, parameter2?: string, parameter3?: string, parameter4?: string, parameter5?: string, parmater6?: string): void;
        static extendedVerbose(message: string, parameter1?: string, parameter2?: string, parameter3?: string, parameter4?: string, parameter5?: string, parmater6?: string): void;
        static appLaunch(appSessionId: string, isDemoMode: boolean, deviceId: string, deviceNumber: string, applicationType: string, locatorServiceUrl: string, aadLoginUrl: string, aadClientId: string): void;
        static appUnhandledError(errorMessage: string, stackTrace: string, errorUrl: string, errorJson: string): void;
        static logon(userSessionId: string): void;
        static logoff(userSessionId: string): void;
        static userMessageDisplay(messageType: string, messageTitle: string, message: string): void;
        static errorMessageDisplay(errorCode: string, errorMessage: string): void;
        static applicationContextSetupLanguagesInvalidLanguage(languageId: string): void;
        static applicationStylesheetsLoadFailed(uri: string, errorCode: string, errorMessage: string): void;
        static applicationLocalStorageNotAvailable(errorMessage: string): void;
        static applicationContextInvalidCatalogImageFormat(): void;
        static applicationContextApplicationContextEntitySetInvalid(entitySetId: string): void;
        static applicationContextApplicationContextEntitySetMultipleTimes(entitySetId: string): void;
        static applicationContextApplicationContextEntitySetNoMethodNumber(): void;
        static applicationFailedToParseError(error: string): void;
        static applicationFailedToParseErrorInvalidJson(error: string): void;
        static applicationGlobalizationResourcesEmpty(): void;
        static applicationGlobalizationResourcesLoadFailed(languageTag: string, errorCode: string, errorMessage: string): void;
        static applicationContextLoadCategoriesFailed(errorCode: string, errorMessage: string): void;
        static applicationLoadChannelConfigurationFailed(component: string, errorCode: string, errorMessage: string): void;
        static applicationContextSetupDebitCashbackLimitFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupCardTypesFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupReturnOrderReasonCodesFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupCustomerTypesFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupCustomerGroupsFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupHardwareStationProfileFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupLanguagesFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupReceiptOptionsFailed(errorCode: string, errorMessage: string): void;
        static applicationContextSetupCashDeclarationsFailed(errorCode: string, errorMessage: string): void;
        static applicationGlobalizationResourcesLoading(languageTag: string): void;
        static applicationGlobalizationResourcesLanguageResolved(languageTag: string): void;
        static applicationLoadEnvironmentConfigurationStorageLoadSucceeded(config: string): void;
        static applicationLoadEnvironmentConfigurationServerLoadSucceeded(config: string): void;
        static applicationLoadEnvironmentConfigurationServerLoadFailed(errorMessage: string): void;
        static applicationUpdateIsRequired(): void;
        static accessWrongDeviceTerminal(): void;
        static modelManagersRetailServerRequestStarted(requestId: string, requestUrl: string): void;
        static modelManagersRetailServerRequestError(requestId: string, requestUrl: string, error: string): void;
        static modelManagersRetailServerRequestFinished(requestId: string, requestUrl: string): void;
        static modelManagersCommerceRuntimeRequestStarted(requestId: string, requestUrl: string): void;
        static modelManagersCommerceRuntimeRequestError(requestId: string, requestUrl: string, error: string): void;
        static modelManagersCommerceRuntimeRequestFinished(requestId: string, requestUrl: string): void;
        static modelManagersCheckDownloadCompleteRequestError(statusText: string): void;
        static modelManagersLocatorServiceRequestStarted(request: string, locatorServiceActivityId: string): void;
        static modelManagersLocatorServiceRequestException(errorMessage: string, locatorServiceActivityId: string): void;
        static modelManagersLocatorServiceRequestFinished(locatorServiceActivityId: string): void;
        static modelManagersServerResponseStatusCode(statusCode: number): void;
        static modelManagersChainedRequestFactorySwitchingToOnline(): void;
        static modelManagersChainedRequestFactorySwitchingToOffline(): void;
        static modelManagersChainedRequestFactoryShiftTransferFailed(currentState: string, errorCode: string, errorMessage: string): void;
        static modelManagersChainedRequestFactoryCartTransferToOfflineFailed(errorCode: string, errorMessage: string): void;
        static modelManagersODataExecuteBatchSuccess(batchRequestUri: string): void;
        static modelManagersODataExecuteBatchFailed(batchRequestUri: string, errorCode: string, errorMessage: string): void;
        static modelManagersRetailServerManagerFactoryCreate(platform: string): void;
        static modelManagersRetailServerManagerFactoryCreateChained(): void;
        static modelManagersRetailServerManagerFactoryCreateOnline(): void;
        static modelManagersCartManagerAddTenderLineToCartFailed(errorCode: string, errorMessage: string): void;
        static modelManagersCartManagerFailedToOverridePriceNoCartLinesProvided(): void;
        static modelManagersCartManagerFailedToOverridePriceNoCartLineOrPriceProvided(): void;
        static modelManagersCustomerManagerCustomerValidationFailed(): void;
        static modelManagersCustomerManagerCustomerIsNull(): void;
        static modelManagersRetailServerOdataRequestResponse(clientRequest: string, serverResponse: string): void;
        static modelManagersRetailServerOdataRequestErrorResponse(clientRequest: string, serverResponse: string): void;
        static modelManagersChainedRequestFactoryShiftTransferToOnlineCreateFailed(errorCode: string, errorMessage: string): void;
        static modelManagersChainedRequestFactoryShiftTransferToOnlineDeleteFailed(errorCode: string, errorMessage: string): void;
        static coreCannotMapResourceMessage(resourceId: string): void;
        static coreCannotMapErrorCode(errorCode: string): void;
        static corePropertyMissingInDeviceActivationSequence(propertyName: string, operationName: string): void;
        static coreRetailOperationStarted(correlationId: string, operationName: string, operationId: number): void;
        static coreOperationManagerRevertToSelf(): void;
        static coreRetailOperationManagerOverride(operationName: string, operationId: number): void;
        static coreRetailOperationHandlerNotFound(operationName: string, operationId: number): void;
        static coreRetailOperationCompleted(correlationId: string, operationName: string, operationId: number): void;
        static coreRetailOperationCanceled(correlationId: string, operationName: string, operationId: number): void;
        static coreRetailOperationFailed(correlationId: string, operationName: string, operationId: number, errorMessage: string): void;
        static coreTriggerExecutionStarted(triggerName: string): void;
        static coreTriggerExecutionCompleted(triggerName: string): void;
        static coreTriggerExecutionCanceled(triggerName: string): void;
        static coreTriggerExecutionFailed(triggerName: string, errorMessage: string): void;
        static coreLogOriginalUnauthorizedRetailServerResponse(errorResourceId: string, errorMessage: string): void;
        static coreLogXmlHttpRequestError(requestUrl: string, message: string): void;
        static coreHelpersProductPropertiesGetTranslation(translationKey: string): void;
        static coreHelpersProductPropertiesPropertyNotExist(propertyName: string): void;
        static coreHelpersProductPropertiesUnitOfMeasureNotExist(unitOfMeasureSymbol: string): void;
        static coreHelpersProductPropertiesVariantPropertyNotExist(propertyName: string): void;
        static coreHelpersProductPropertiesTranslationPropertyNotFound(translationKey: string): void;
        static coreHelpersProductPropertiesVariantNotFound(variantId: number, productId: number): void;
        static coreHelpersProductPropertiesInputParameterProductIsUndefined(propertyName: string): void;
        static coreHelpersProductPropertiesInputParameterPropertyNameIsInvalid(itemId: string, propertyName: string): void;
        static coreHelpersProductPropertiesProductNotHaveVariant(productId: string, variantId: number): void;
        static coreHelpersProductPropertiesProductNotHaveProperty(productId: string, propertyName: string): void;
        static coreHelpersUnrecognizedAddressComponent(addressComponent: number): void;
        static coreHelpersInvalidManualDiscountType(manualDiscountType: number): void;
        static coreHelpersInvalidCustomerDiscountType(customerDiscountType: number): void;
        static coreHelpersInvalidDiscountLineType(discountLineType: number): void;
        static coreHelpersUnknownAddressType(addressType: number): void;
        static coreTenderTypeMapOperationHasNoTenderType(operationId: number): void;
        static coreTenderTypeMapMultipleTendersOfSameType(): void;
        static coreBindingHandlersLoadImageFailed(src: string): void;
        static coreFormattersCartLineWrongInputParameters(propertyName: string, data: string): void;
        static coreTenderTypeMapTenderTypeNotFound(tenderTypeId: string): void;
        static coreApplicationStorageSetItemFailure(storageKey: string, errorMessage: string): void;
        static coreApplicationStorageSetItemFailureRecoveryUnsuccessful(storageKey: string, errorMessage: string): void;
        static coreLogUserAuthenticationRetailServerResponse(errorResourceId: string, errorMessage: string): void;
        static coreRetailCheckOpenDrawerStatusExecutionStart(): void;
        static coreRetailCheckOpenDrawerStatusExecutionCompleted(): void;
        static coreRetailCheckOpenDrawerStatusExecutionFailed(errorCode: string, errorMessage: string): void;
        static operationLogOffComplete(): void;
        static operationLogOffFailed(errorCode: string, errorMessage: string): void;
        static operationAddGiftCard(giftCardId: string, amount: number, currency: string, lineDescription: string): void;
        static operationIssueGiftCard(giftCardId: string, amount: number, currency: string, lineDescription: string): void;
        static operationCloseShift(): void;
        static operationLocateServerUrl(url: string): void;
        static operationUpdateServerUrl(url: string): void;
        static operationDeviceActivationUnhandledError(error: string): void;
        static operationTimeClockNotEnabled(): void;
        static operationPickingAndReceivingGetAllOrdersFailed(): void;
        static operationPickingAndReceivingUpdatePurchaseOrderFailed(orderId: string): void;
        static operationPickingAndReceivingCommitPurchaseOrderFailed(journalId: string): void;
        static operationPickingAndReceivingGetPurchaseOrderFailed(journalId: string): void;
        static operationPickingAndReceivingUpdateTransderOrderFailed(orderId: string): void;
        static operationPickingAndReceivingCommitTransferOrderFailed(journalId: string): void;
        static operationPickingAndReceivingGetTransferOrderFailed(journalId: string): void;
        static operationPickingAndReceivingUpdatePickingListFailed(orderId: string): void;
        static operationPickingAndReceivingCommitPickingListFailed(journalId: string): void;
        static operationPickingAndReceivingGetPickingListFailed(journalId: string): void;
        static retailServerRequestRedirection(redirectionUrl: string): void;
        static operationItemSaleCreateCartLinesStarted(correlationId: string): void;
        static operationItemSaleCreateCartLinesFinished(correlationId: string, successful: boolean): void;
        static operationItemSaleGetProductSaleDetailsStarted(correlationId: string): void;
        static operationItemSaleGetProductSaleDetailsFinished(correlationId: string, successful: boolean): void;
        static operationBlindCloseSharedShiftFailedOnRevertToSelfDuringCancellation(shiftId: number, staffId: string): void;
        static peripheralsCashDrawerOpening(deviceName: string, deviceType: string): void;
        static peripheralsMSRKeyboardSwipeParserLog(message: string): void;
        static peripheralsCompositeBarcodeScannerObjectNotDefined(objectName: string): void;
        static peripheralsHardwareStationContextActionRequestSucceeded(actionRequest: string): void;
        static peripheralsHardwareStationContextActionRequestFailed(actionRequest: string, errors: string): void;
        static peripheralsUnsupportedPrinterType(printerType: string): void;
        static peripheralsBarcodeScannerGetDeviceSelectorFailed(errorMessage: string): void;
        static peripheralsBarcodeScannerGetBluetoothDeviceSelectorFailed(errorMessage: string): void;
        static peripheralsBarcodeScannerRfCommDeviceServiceNotFound(): void;
        static peripheralsBarcodeScannerEnableFailed(errorMessage: string): void;
        static peripheralsMagneticStripeReaderGetDeviceSelectorFailed(errorMessage: string): void;
        static peripheralsMagneticStripeReaderGetBluetoothDeviceSelectorFailed(errorMessage: string): void;
        static peripheralsMagneticStripeReaderRfCommDeviceServiceNotFound(): void;
        static peripheralsMagneticStripeReaderInitializeFailed(errorMessage: string): void;
        static peripheralsMagneticStripeReaderEnableFailed(errorMessage: string): void;
        static peripheralsProximityOpenDeviceFailed(errorMessage: string): void;
        static peripheralsProximityNotAvailable(): void;
        static peripheralsLongPollingLockGetDataError(errors: string): void;
        static peripheralsLongPollingLockGetDataUnhandledError(message: string): void;
        static peripheralsNetworkPaymentTerminalIsNotSupported(): void;
        static librariesWinJsListViewShown(elementId: string): void;
        static librariesWinJsListViewItemClick(elementId: string): void;
        static librariesNumpadEnterKey(textFieldValue: string): void;
        static librariesAuthenticationProviderLoginStarted(requestId: string, details: string): void;
        static librariesAuthenticationProviderLoginFinished(requestId: string, details: string): void;
        static librariesAuthenticationProviderAcquireTokenStarted(requestId: string, resourceId: string): void;
        static librariesAuthenticationProviderAcquireTokenFinished(requestId: string): void;
        static helpersActivityHelperAddCartLinesStarted(correlationId: string): void;
        static helpersActivityHelperAddCartLinesFinished(correlationId: string): void;
        static viewsLoginLoginViewSignInStarted(): void;
        static viewsLoginLoginViewSignInFinished(): void;
        static viewsCloudDeviceActivationViewActivationFailed(): void;
        static viewsHomeTileClick(action: string): void;
        static viewsOrderPaymentViewPaymentInitiated(): void;
        static viewsCustomerDetailsLoaded(): void;
        static viewsCustomerDetailsError(errorCode: string, errorMessage: string): void;
        static viewsCustomerDetailsAddCustomerFailed(): void;
        static viewsMerchandisingSearchViewSearchClick(searchTerm: string): void;
        static viewsMerchandisingSearchViewProductButtonClick(searchTerm: string): void;
        static viewsMerchandisingSearchViewCustomerButtonClick(searchTerm: string): void;
        static viewsMerchandisingSearchViewAddToCartClick(numberOfItems: number): void;
        static viewsMerchandisingSearchViewQuickSaleClick(numberOfItems: number): void;
        static viewsMerchandisingSearchViewInvalidProductOperation(): void;
        static viewsMerchandisingSearchViewInvalidCustomerOperation(): void;
        static viewsMerchandisingProductDetailsLoadStarted(): void;
        static viewsMerchandisingProductDetailsAddItem(): void;
        static viewsMerchandisingProductDetailsQuickSale(): void;
        static viewsMerchandisingProductDetailsLoaded(): void;
        static viewsMerchandisingProductDetailsKitVariantNotFound(kitVariantId: number, productId: number): void;
        static viewsMerchandisingPriceCheckViewGetPriceFinished(): void;
        static viewsMerchandisingCatalogsCatalogClicked(catalogId: string, catalogName: string): void;
        static viewsMerchandisingCategoriesViewLoaded(): void;
        static viewsCartCartViewPayQuickCash(): void;
        static viewsCartCartViewShowPrintDialogFailed(errorCode: string, errorMessage: string): void;
        static viewsCartShowJournalViewLoaded(): void;
        static viewsCartShowJournalViewRetrieveProductFailed(productId: number): void;
        static viewsControlsCommonHeaderSearch(searchTerm: string): void;
        static viewsControlsCommonHeaderFilterIconClick(): void;
        static viewsControlsCommonHeaderCategoryInTreeClicked(categoryName: string): void;
        static viewsControlsModalDialogRendered(): void;
        static viewsControlsRefinersApplyFilters(): void;
        static viewsControlsRefinersTypeNotSupported(refiner: string): void;
        static viewsControlsRefinersDisplayTemplateNotSupported(refiner: string): void;
        static viewsControlsRefinersWrongInputParameters(refiner: string): void;
        static viewsControlsPrintReceiptShown(): void;
        static viewsControlsPrintReceiptSkipped(): void;
        static viewsControlsPrintReceiptPrinted(): void;
        static viewsControlsCashbackDialogOnShowingParametersUndefined(): void;
        static viewsControlsOrderCheckoutDialogOnShowingParametersUndefined(): void;
        static viewsMerchandisingAllStoresViewConstructorArgumentUndefined(argument: string): void;
        static viewsMerchandisingPickingAndReceivingDetailsViewLoadJournalFailed(journalId: string): void;
        static viewsCustomerAddEditViewAddCustomerFailed(): void;
        static viewsCustomerAddEditViewAddUpdateNewCustomerFailed(): void;
        static viewsCustomerPickUpInStoreViewBingMapsFaild(message: string): void;
        static viewsCustomerPickUpInStoreViewBingMapsFailedToInitialize(message: string): void;
        static viewsCustomerAddressAddEditViewDownloadTaxGroupsFailed(errorCode: string, errorMessage: string): void;
        static viewsDailyOperationsCashManagementViewOperationFailed(errorCode: string, errorMessage: string): void;
        static viewsControlsKnockoutCustomerCardDataPropertyRequired(): void;
        static viewsControlsKnockoutParallaxBackgroundElementRequired(): void;
        static viewsTutorialVideoDialogVideoElementThrowsError(errorMessage: string): void;
        static viewModelCartAddProductsToCart(): void;
        static viewModelCartVoidProductsStarted(): void;
        static viewModelCartVoidProductsFinished(success: boolean): void;
        static viewModelCartGetProductDetailsFailed(): void;
        static viewModelGetCustomerBalanceFailed(errorCode: string, errorMessage: string): void;
        static viewModelGetCustomerLoyaltyCardsFailed(errorCode: string, errorMessage: string): void;
        static viewModelUnsupportedBarcodeMaskType(maskType: string): void;
        static viewModelCartProcessScanResultStarted(correlationId: string, barcodeMaskType: string): void;
        static viewModelCartProcessScanResultFinished(correlationId: string, successful: boolean): void;
        static viewModelLoginDeviceActivationFailed(deviceId: string, terminalId: string, errorResourceIds: string): void;
        static viewModelLoginRetrieveUserAuthenticationTokenFailed(tokenResourceId: string, errorDetails: string): void;
        static viewModelLoginRetailServerDiscoveryFailed(locatorServiceUrl: string, tenantId: string, errorDetails: string): void;
        static viewModelLoginRetrieveDeviceInformationFailed(): void;
        static viewModelLoginFailed(errorCode: string, errorMessage: string): void;
        static viewModelDeleteExpiredSessionFailed(statusText: string): void;
        static viewModelRetrieveBlobStorageUriFailed(): void;
        static viewModelGetTerminalIdFailed(): void;
        static viewModelGetTerminalDataStoreNameFailed(terminalId: string): void;
        static viewModelGetDownloadIntervalFailed(dataStoreName: string): void;
        static viewModelCheckInitialSyncFailed(statusText: string): void;
        static viewModelGetDownloadSessionsFailed(dataStoreName: string): void;
        static viewModelDownloadFileFailed(statusText: string): void;
        static viewModelDownloadFileBrokerRequestFailed(errorMessage: string): void;
        static viewModelApplyToOfflineDbFailed(statusText: string): void;
        static viewModelApplyToOfflineDbBrokerRequestFailed(statusText: string): void;
        static viewModelUpdateDownloadSessionStatusBrokerRequestFailed(statusText: string): void;
        static viewModelUpdateDownloadSessionStatusFailed(): void;
        static viewModelGetUploadIntervalFailed(dataStoreName: string): void;
        static viewModelGetUploadJobDefinitionsFailed(dataStoreName: string): void;
        static viewModelLoadUploadTransactionsFailed(statusText: string): void;
        static viewModelSyncOfflineTransactionsFailed(): void;
        static viewModelPurgeOfflineTransactionsFailed(statusText: string): void;
        static viewModelGetDownloadLinkFailed(dataStoreName: string, downloadSessionId: number): void;
        static viewModelGetOfflineSyncStatsFailed(statusText: string): void;
        static viewModelProductDetailsComponentsNotInKit(): void;
        static viewModelProductDetailsKitVariantNotFound(kitVariantId: number, productId: number): void;
        static viewModelKitDisassemblyRetrievedKitProduct(): void;
        static viewModelKitDisassemblyKitDisassemblyBlocked(): void;
        static viewModelAddressAddEditGetAddressFromZipCodeFailed(): void;
        static viewModelGetAffiliationsFailed(): void;
        static viewModelPriceCheckContextEntitySetNone(): void;
        static viewModelPriceCheckContextEntitySetMultipleTimes(entitySetId: string): void;
        static viewModelPriceCheckContextEntitySetNoMethod(): void;
        static viewModelPriceCheckGetProductPriceFailed(errorCode: string, errorMessage: string): void;
        static viewModelPriceCheckGetCustomerFailed(errorCode: string, errorMessage: string): void;
        static viewModelPriceCheckGetStoreDetailsFailed(errorCode: string, errorMessage: string): void;
        static viewModelPriceCheckGetActivePriceFailed(errorCode: string, errorMessage: string): void;
        static viewModelPaymentCardSwipeNotSupported(operationId: number): void;
        static viewModelCustomerAddEditUnknownCustomerType(customerType: string): void;
        static viewModelStockCountDetailsSearchProductsByItemsFailed(): void;
        static viewModelStoreOperationsGetCurrenciesForStoreFailed(): void;
        static viewModelPickingAndReceivingDetailsSearchProductsByIdFailed(): void;
        static cloudPosBrowserNotSupported(userAgentDetails: string, errorDetails: string): void;
        static coreOperationValidatorsNoCartOnCartValidator(src: string): void;
        static viewModelProductSearchViewModelSearchProductsByTextFailed(searchText: string, refinerValues: string, error: string): void;
        static viewModelProductSearchViewModelGetRefinersByTextFailed(searchText: string, error: string): void;
        static viewModelProductSearchViewModelGetRefinerValuesByTextFailed(searchText: string, refinerId: number, refinerSourceValue: number, error: string): void;
        static viewModelProductsViewModelAddItemsToCart(itemDetails: string, isQuickSale: boolean): void;
        static viewsModelProductsViewModelSearchProductsByCategoryFailed(categoryId: number, refinerValues: string, error: string): void;
        static viewsModelProductsViewModelGetRefinersByCategoryFailed(categoryId: number, error: string): void;
        static viewsModelProductsViewModelGetRefinerValuesByCategoryFailed(categoryId: number, refinerId: number, refinerSourceValue: number, error: string): void;
        static viewModelProductsViewModelGetProductDetailsFailed(productSearchCriteria: string, error: string): void;
        static viewModelSearchViewModelAddCustomerToCartFailed(customerAccountNumber: string, error: string): void;
        static viewModelSearchViewModelGetProductDetailsFailed(productSearchCriteria: string, error: string): void;
        static taskRecorderContinueRecording(sessionId: string, sessionName: string): void;
        static taskRecorderPauseRecording(sessionId: string, sessionName: string): void;
        static taskRecorderStopRecording(sessionId: string, sessionName: string): void;
        static taskRecorderEndTask(sessionId: string, sessionName: string): void;
        static taskRecorderHandleAction(actionText: string): void;
        static taskRecorderScreenshotsUploadingFailed(errors: string): void;
        static taskRecorderDownloadFile(sourceUrl: string, destinationPath: string): void;
        static taskRecorderShowSaveDialog(suggestedFileName: string, fileTypeChoice: string): void;
        static taskRecorderSavingFileFailed(errors: string): void;
        static taskRecorderSavingFileFinished(url: string): void;
        static taskRecorderSavingFileCanceled(url: string): void;
        static taskRecorderFileWasSaved(fileName: string): void;
        static taskRecorderSaveXMLFailed(sessionId: string, errors: string): void;
        static taskRecorderSaveTrainingDocumentFailed(sessionId: string, errors: string): void;
        static taskRecorderDeleteFolderFromLocalStorageFailed(folder: string, errors: string): void;
        static taskRecorderSaveBpmPackageFailed(sessionId: string, errors: string): void;
        static taskRecorderSaveSessionAsRecordingBundleFailed(sessionId: string): void;
        static viewsAsyncImageControlInvalidDefaultImage(): void;
    }
}
//
// DocumentBrowserViewController.swift
// MrHappyoI
//
// Copyright (c) 2018 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit


public class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    private var transitioningController: UIDocumentBrowserTransitionController?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    public func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("\(R.String.newDocumentName.localized()).happyo1")
        let newDocument = Document(fileURL: tempURL)
        newDocument.save(to: tempURL, for: .forCreating) { isSaveSucceeded in
            guard isSaveSucceeded else { importHandler(nil, .none); return }
            newDocument.close { isCloseSucceeded in
                guard isCloseSucceeded else { importHandler(nil, .none); return }
                importHandler(tempURL, .move)
            }
        }
    }
    
    public func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    public func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    public func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitioningController
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitioningController
    }

    // MARK: Document Presentation
    
    public func presentDocument(at documentURL: URL) {
        let (navViewController, editorViewController) = EditorViewController.instantiateFromStoryboard()
        editorViewController.loadViewIfNeeded()

        navViewController.transitioningDelegate = self
        navViewController.modalPresentationStyle = .fullScreen
        let transitioningController = transitionController(forDocumentAt: documentURL)
        transitioningController.targetView = editorViewController.slideViewController.slideView
        self.transitioningController = transitioningController

        let document = Document(fileURL: documentURL)
        document.errorHandler = { (error, completionHandler) in
            func handleError(error: Error, completionHandler: @escaping (/* isRecovered: */ Bool) -> Void) {
                let title = R.String.errorFailedToOpen.localized()
                let message = (error as? LocalizedError)?.errorDescription
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default, handler: { _ in
                    completionHandler(false)
                }))
                self.present(alert, animated: true)
            }
            if Thread.isMainThread {
                handleError(error: error, completionHandler: completionHandler)
            } else {
                DispatchQueue.main.async {
                    handleError(error: error, completionHandler: completionHandler)
                }
            }
        }
        editorViewController.setDocument(document) { isSucceeded in
            document.errorHandler = nil
            if isSucceeded {
                self.present(navViewController, animated: true, completion: nil)
            }
        }
    }
}

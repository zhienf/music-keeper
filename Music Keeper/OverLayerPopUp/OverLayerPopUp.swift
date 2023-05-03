//
//  OverLayerPopUp.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class OverLayerPopUp: UIViewController {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popUpView: UIView!
    @IBAction func cancelButton(_ sender: Any) {
        hide()
    }
    @IBAction func saveButton(_ sender: Any) {
    }
    
    init() {
        super.init(nibName: "OverLayerPopUp", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configView()
    }
    
    func configView() {
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.popUpView.alpha = 0
        self.popUpView.layer.cornerRadius = 10
    }

    func appear(sender: UIViewController) {
        sender.present(self, animated: false) {
            self.show()
        }
    }
    
    private func show() {
        self.backView.alpha = 1
        self.popUpView.alpha = 1
    }
    
    func hide() {
        self.backView.alpha = 0
        self.popUpView.alpha = 0
        self.dismiss(animated: false)
        self.removeFromParent()
    }
}

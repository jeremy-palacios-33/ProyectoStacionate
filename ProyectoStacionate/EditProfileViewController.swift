//
//  EditProfileViewController.swift
//  ProyectoStacionate
//
//  Created by DAMII on 20/12/25.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet weak var userImageView: UIImageView!

    var profileImage: UIImage?   // 👈 imagen recibida

    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = profileImage {
            userImageView.image = image
        } else {
            userImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }
}


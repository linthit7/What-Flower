//
//  ViewController.swift
//  WhatFlower
//
//  Created by Lin Thit Khant on 10/22/22.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var flowerInfo: UILabel!

    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let photo = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: photo) else {
                fatalError("Error converting UIImage to CIImage.")
            }
            detect(flowerImage: ciimage)
        }
        
        imagePicker.dismiss(animated: true)
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Error getting model from FlowerClassifier.")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results else {
                fatalError("Error getting results from request.")
            }
            
            if let classification = results.first as? VNClassificationObservation {
                self.navigationItem.title = classification.identifier.capitalized
                self.request(name: classification.identifier.capitalized)
            } else {
                self.navigationItem.title = "Unidentifiable flower"
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func request(name: String) {
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : name,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"
          ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                let flowerJSON: JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                self.flowerInfo.text = flowerDescription
                
                let flowerImage = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.photoView.sd_setImage(with: URL(string: flowerImage))
            }
        }
        
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}


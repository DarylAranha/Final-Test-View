import UIKit

class AddAndEditViewController: UIViewController
{
    // UI References
    @IBOutlet weak var AddEditTitleLabel: UILabel!
    @IBOutlet weak var UpdateButton: UIButton!
    
    // musician Fields
    @IBOutlet weak var musicianIDTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var genresTextField: UITextField!
    @IBOutlet weak var instrumentsTextField: UITextField!
    @IBOutlet weak var labelsTextField: UITextField!
    @IBOutlet weak var spousesTextField: UITextField!
    @IBOutlet weak var childrensTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!

    
    var musician: Musician?
    var crudViewController: APICRUDViewController? // Updated from musicianViewController
    var musicianUpdateCallback: (() -> Void)? // Updated from MovieViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let musician = musician
        {
            print(musician.genres)
            // Editing existing musician
            musicianIDTextField.text = String(musician.music_id)
            fullNameTextField.text = musician.fullName
//            genresTextField.text = musician.genres.joined(separator: ", ")
//            instrumentsTextField.text = musician.instruments.joined(separator: ", ")
//            labelsTextField.text = musician.labels.joined(separator: ", ")
//            spousesTextField.text = musician.spouses?.joined(separator: ", ")
//            childrensTextField.text = musician.children?.joined(separator: ", ")
            dobTextField.text = musician.born
            yearTextField.text = musician.yearsActive
            
            AddEditTitleLabel.text = "Edit Musician"
            UpdateButton.setTitle("Update", for: .normal)
        }
        else
        {
            AddEditTitleLabel.text = "Add Musician"
            UpdateButton.setTitle("Add", for: .normal)
        }
    }
    
    @IBAction func CancelButton_Pressed(_ sender: UIButton)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func UpdateButton_Pressed(_ sender: UIButton)
    {
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available.")
            return
        }
        
        let urlString: String
        let requestType: String
        
        if let musician = musician {
            requestType = "PUT"
            urlString = "https://mdev1004-2023-final-test.onrender.com/api/update/\(musician._id)"
        } else {
            requestType = "POST"
            urlString = "https://mdev1004-2023-final-test.onrender.com/api/add"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        // Explicitly mention the types of the data
        let id: String = musician?._id ?? UUID().uuidString
        let musicianID: String = musicianIDTextField.text ?? ""
        let fullName: String = fullNameTextField.text ?? ""
        let genres: String = genresTextField.text ?? ""
        let instruments: String = instrumentsTextField.text ?? ""
        let labels: String = labelsTextField.text ?? ""
        let spouses: String = spousesTextField.text ?? ""
        let children: String = childrensTextField.text ?? ""
        let year: String = yearTextField.text ?? ""
        let dob: String = dobTextField.text ?? ""

        // Create the musician with the parsed data

        let musician = Musician(
            _id: id,
            music_id: musicianID,
            fullName: fullName,
            genres: [genres],
            instruments: [instruments],
            labels: [labels],
            born: dob,
            yearsActive: year,
            spouses: [spouses],
            children: [children],
            relatives: nil,
            notableWorks: [],
            imageURL: nil
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add the AuthToken to the request headers
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(musician)
        } catch {
            print("Failed to encode musician: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error
            {
                print("Failed to send request: \(error)")
                return
            }
            
            DispatchQueue.main.async
            {
                self?.dismiss(animated: true)
                {
                    self?.musicianUpdateCallback?()
                }
            }
        }
        
        task.resume()
    }
}


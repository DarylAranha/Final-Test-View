import UIKit

class APICRUDViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    
    @IBOutlet weak var tableView: UITableView!
        
    var musicians: [Musician] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        fetchMusicians { [weak self] musicians, error in
            DispatchQueue.main.async {
                if let musicians = musicians {
                    if musicians.isEmpty {
                        // Display a message for no data
                        self?.displayErrorMessage("No musicians available.")
                    } else {
                        self?.musicians = musicians
                        self?.tableView.reloadData()
                    }
                } else if let error = error {
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        // Handle timeout error
                        self?.displayErrorMessage("Request timed out.")
                    } else {
                        // Handle other errors
                        self?.displayErrorMessage(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicians.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicianCell", for: indexPath) as! MusicianTableViewCell
                        
                
        let musician = musicians[indexPath.row]
        
        cell.nameLabel?.text = musician.fullName
        cell.bornLabel?.text = musician.born
        
        return cell
    }
    
    func displayErrorMessage(_ message: String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchMusicians(completion: @escaping ([Musician]?, Error?) -> Void) {
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else {
            print("AuthToken not available.")
            completion(nil, nil)
            return
        }
        
        guard let url = URL(string: "https://mdev1004-2023-final-test.onrender.com/api/list") else
        {
            print("URL Error")
            completion(nil, nil) // Handle URL error
            return
        }
        
        var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Network Error")
                completion(nil, error) // Handle network error
                return
            }

            guard let data = data else {
                print("Empty Response")
                completion(nil, nil) // Handle empty response
                return
            }

            do {
                print("Decoding JSON Data...")
                print(data)
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print(json)
                if let success = json?["success"] as? Bool, success == true
                {
                    if let musiciansData = json?["data"] as? [[String: Any]] {
                                do {
                                    let jsonData = try JSONSerialization.data(withJSONObject: musiciansData, options: [])
                                    let decodedMusicians = try JSONDecoder().decode([Musician].self, from: jsonData)
                                    completion(decodedMusicians, nil) // Success
                                } catch {
                                    print("Error decoding musicians data:", error)
                                    completion(nil, error) // Handle decoding error
                                }
                            } else {
                                print("Missing 'data' field in JSON response")
                                completion(nil, nil) // Handle missing data field
                            }

                } else {
                    print("API request unsuccessful")
                    let errorMessage = json?["msg"] as? String ?? "Unknown error"
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    completion(nil, error) // Handle API request unsuccessful
                }
            } catch {
                print("Error Decoding JSON Data")
                completion(nil, error) // Handle JSON decoding error
            }
        }.resume()
    }
    
    // New for ICE8
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "AddEditSegue", sender: indexPath)
    }
        
    // Swipe Left Gesture
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let musician = musicians[indexPath.row]
            ShowDeleteConfirmationAlert(for: musician) { confirmed in
                if confirmed {
                    self.deleteMusician(at: indexPath)
                }
            }
        }
    }
    
    @IBAction func AddButton_Pressed(_ sender: UIButton)
    {
        performSegue(withIdentifier: "AddEditSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "AddEditSegue"
        {
            if let addEditVC = segue.destination as? AddEditAPICRUDViewController
            {
                addEditVC.crudViewController = self
                if let indexPath = sender as? IndexPath {
                    // Editing existing musician
                    let musician = musicians[indexPath.row]
                    addEditVC.musician = musician
                } else {
                    // Adding new musician
                    addEditVC.musician = nil
                }
                
                // Set the callback closure to reload movies
                addEditVC.musicianUpdateCallback = { [weak self] in
                    self?.fetchMusicians { musicians, error in
                        if let musicians = musicians {
                            self?.musicians = musicians
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        } else if let error = error {
                            print("Failed to fetch musicians: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func ShowDeleteConfirmationAlert(for musician: Musician, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete Musician", message: "Are you sure you want to delete this musician?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        })

        present(alert, animated: true, completion: nil)
    }
    
    func deleteMusician(at indexPath: IndexPath) {
        let musician = musicians[indexPath.row]

        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else {
            print("AuthToken not available.")
            return
        }

        guard let url = URL(string: "https://mdev1004-2023-final-test.onrender.com/api/delete/\(musician._id)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Failed to delete musician: \(error)")
                return
            }

            DispatchQueue.main.async {
                self?.musicians.remove(at: indexPath.row) // Update the musicians array
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }

        task.resume()
    }
    
    // New for ICE 9
    @IBAction func logoutButtonPressed(_ sender: UIButton)
    {
        // Remove the token from UserDefaults or local storage to indicate logout
        UserDefaults.standard.removeObject(forKey: "AuthToken")
        
        // Clear the username and password in the LoginViewController
        APILoginViewController.shared?.ClearLoginTextFields()
        
        // unwind
        performSegue(withIdentifier: "unwindToLogin", sender: self)
    }

}

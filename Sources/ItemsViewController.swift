import UIKit

class ItemsViewController: UITableViewController {

    private let repository = ServiceContainer.shared.itemRepository
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Item")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repository.catalogItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath)
        let item = repository.catalogItems[indexPath.row]
        cell.textLabel?.text = item.description
        cell.imageView?.image = item.thumbnail
        return cell
    }
    
    private func onImagePicked(_ originalImage: UIImage) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let item = Item()
        let thumbSize = originalImage.size.resized(to: CGSize(width: 80, height: 80), ratio: .aspectFill)
        item.originalImage = originalImage
        item.thumbnail = originalImage.resized(to: thumbSize)
        item.description = formatter.string(from: item.timestamp)
        repository.insert(item)
        tableView.reloadData()
    }
    
    @objc private func addItem() {
        let vc = AddItemViewController()
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func _addItem() {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        }
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension ItemsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.onImagePicked(image)
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

import UIKit

class ItemsViewController: UITableViewController {

    private let repository = ServiceContainer.shared.itemRepository
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Item")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddItem))
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
    
    private func addItem(_ originalImage: UIImage, caption: String) {
        let item = Item()
        let thumbSize = originalImage.size.resized(to: CGSize(width: 80, height: 80), ratio: .aspectFill)
        item.originalImage = originalImage
        item.thumbnail = originalImage.resized(to: thumbSize)
        item.description = caption
        repository.insert(item)
        tableView.reloadData()
    }
    
    @objc private func showAddItem() {
        let vc = AddItemViewController()
        vc.doneHandler = { [unowned self, vc] in
            if let image = vc.capturedImage {
                self.addItem(image, caption: vc.caption)
                vc.dismiss(animated: true, completion: nil)
            }
        }
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
}

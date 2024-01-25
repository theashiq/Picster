//
//  HomeViewController.swift
//  Picster
//
//  Created by mac 2019 on 1/17/24.
//

import UIKit
import CHTCollectionViewWaterfallLayout

class HomeViewController: UIViewController{
    static var title = "Home"
    
    private var collectionView: UICollectionView!
    
    private var data: [FlickrMediaItemViewModel] = []
    private var isDataLoadingEnabled = false
    private var isDataLoading = false
    private var isNextPageAvailable = false
    private var nextPageNumber = 1
    private var scrollOffsetBeforeLoading = CGPoint(x: 0, y: 0)
    
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        configure()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Feed"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    
    private func configure(){
        if UserPreferenceManager.isTopicPreferenceExist(){
            isDataLoadingEnabled = true
            loadContents()
        }
        else{
            let preferenceVC = UserPreferenceViewController()
            preferenceVC.dismissDelegate = self
            present(preferenceVC, animated: true)
        }
        
        configureCollectionView()
    }
    
    
    private func configureCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = .init(width: view.bounds.width / 3 - 10, height: 200)
        
        let waterfallLayout = CHTCollectionViewWaterfallLayout()
        waterfallLayout.columnCount = 3
        waterfallLayout.itemRenderDirection = .leftToRight
        
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: waterfallLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(FlickrItemCollectionCell.self, forCellWithReuseIdentifier: FlickrItemCollectionCell.reuseIdentifier)
        
        
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        view.backgroundColor = .brown
    }
    
    private func loadContents(){
        
        guard isDataLoadingEnabled else { return }
        guard !isNextPageAvailable else { return }
        guard !isDataLoading else { return }
        isDataLoading = true
        
        Task{
            await FlickrApi.shared.getFeed(for: nextPageNumber) { [weak self] result in
                guard let self else {
                    self?.isDataLoading = false
                    return
                }
                
                switch result{
                case .success(let items):
                    isNextPageAvailable =  items.count < FlickrApi.perPageItemCount
                    data.append(contentsOf: items.map{FlickrMediaItemViewModel(feedItem: $0)})
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.collectionView.contentOffset = self.scrollOffsetBeforeLoading
                    }
                case .failure(let error):
                    print(error)
                }
                nextPageNumber += 1
                isDataLoading = false
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        
        collectionView.frame = view.bounds
        collectionView.reloadData()
    }
    
    
}


extension HomeViewController: UserPreferenceDelegate{
    
    func onDismiss() {
        isDataLoadingEnabled = true
        loadContents()
    }
    
}

extension HomeViewController: CHTCollectionViewDelegateWaterfallLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = data[indexPath.row].width
        let h = data[indexPath.row].height
        return CGSize(width: w, height: h)
    }
    
    
}

extension HomeViewController: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        if contentOffsetY >= (scrollView.contentSize.height - scrollView.bounds.height) - 20 /* Needed offset */ {
            scrollOffsetBeforeLoading = scrollView.contentOffset
            loadContents()
        }
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FlickrItemCollectionCell.reuseIdentifier, for: indexPath) as? FlickrItemCollectionCell else{
            return UICollectionViewCell()
        }
        
        if let url = URL(string: data[indexPath.row].urlString){
            cell.configure(with: url)
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
}

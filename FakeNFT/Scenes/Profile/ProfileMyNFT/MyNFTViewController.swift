//
//  ProfileMyNFTViewController.swift
//  FakeNFT
//
//  Created by Ann Goncharova on 15.11.2023.
//

import UIKit

final class MyNFTViewController: UIViewController, UIGestureRecognizerDelegate {
    private let viewModel: MyNFTViewModelProtocol
    private let nftIDs: [String]
    private let likedIDs: [String]
    private var badConnection = false
    // кнопка назад
    private lazy var backButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: Asset.backButton.image,
            style: .plain,
            target: self,
            action: #selector(didTapBackButton))
        button.tintColor = .borderColor
        return button
    }()
    // кнопка сортировки
    private lazy var sortButton = UIBarButtonItem(
        image: Asset.sortButton.image,
        style: .plain,
        target: self,
        action: #selector(didTapSortButton)
    )
    // лейбл при отсутствии нфт
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Profile.emptyNFTLabel // У вас ещё нет NFT
        label.font = .bodyBold17
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        view.backgroundColor = .screenBackground
        addEdgeSwipeBackGesture()
        bind()
    }
    
    init(nftIDs: [String], likedIDs: [String]) {
        self.nftIDs = nftIDs
        self.likedIDs = likedIDs
        self.viewModel = MyNFTViewModel(nftIDs: nftIDs, likedIDs: likedIDs)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let sortOrder = UserDefaults.standard.data(forKey: "sortOrder") {
            let order = try? PropertyListDecoder().decode(MyNFTViewModel.Sort.self, from: sortOrder)
            self.viewModel.sort = order
        } else {
            self.viewModel.sort = .rating
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if badConnection { viewModel.getMyNFTs(nftIDs: nftIDs) }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func bind() {
        viewModel.onChange = { [weak self] in
            self?.badConnection = false
            guard
                let view = self?.view as? MyNFTView,
                let nfts = self?.viewModel.myNFTs else { return }
            view.updateNFT(nfts: nfts)
        }
        
        viewModel.onError = { [weak self] error in
            self?.badConnection = true
            let alert = UIAlertController(
                title: L10n.Profile.noInternet,
                message: error.localizedDescription,
                preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            alert.addAction(action)
            self?.present(alert, animated: true)
        }
    }
    
    @objc private func didTapBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapSortButton() {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Profile.sort, // Сортировка
            preferredStyle: .actionSheet
        )
                
        let sortByPriceAction = UIAlertAction(title: L10n.Profile.byPrice, style: .default) { [weak self] _ in
            self?.viewModel.sort = .price
            self?.saveSortOrder(order: .price)
        }
        let sortByRatingAction = UIAlertAction(title: L10n.Profile.byRaiting, style: .default) { [weak self] _ in
            self?.viewModel.sort = .rating
            self?.saveSortOrder(order: .rating)
        }
        let sortByNameAction = UIAlertAction(title: L10n.Profile.byName, style: .default) { [weak self] _ in
            self?.viewModel.sort = .name
            self?.saveSortOrder(order: .name)
        }
        let closeAction = UIAlertAction(title: L10n.Profile.close, style: .cancel)
        
        alert.addAction(sortByPriceAction)
        alert.addAction(sortByRatingAction)
        alert.addAction(sortByNameAction)
        alert.addAction(closeAction)
        
        present(alert, animated: true)
    }
    
    private func saveSortOrder(order: MyNFTViewModel.Sort) {
        let data = try? PropertyListEncoder().encode(order)
        UserDefaults.standard.set(data, forKey: "sortOrder")
    }
    
    func setupView() {
        if nftIDs.isEmpty {
            view.backgroundColor = .screenBackground
            setupNavBar(emptyNFTs: true)
            setupEmptyLabel()
        } else {
            self.view = MyNFTView(frame: .zero, viewModel: self.viewModel)
            setupNavBar(emptyNFTs: false)
        }
    }
    
    func setupNavBar(emptyNFTs: Bool) {
        navigationController?.navigationBar.tintColor = .borderColor
        navigationItem.leftBarButtonItem = backButton
        backButton.accessibilityIdentifier = "backButton"
        if !emptyNFTs {
            navigationItem.rightBarButtonItem = sortButton
            navigationItem.title = L10n.Profile.myNFT
            sortButton.tintColor = .borderColor
        }
    }
    
    func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

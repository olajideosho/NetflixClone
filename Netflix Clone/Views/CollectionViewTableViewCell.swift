//
//  CollectionViewTableViewCell.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 10/09/2022.
//

import UIKit

protocol CollectionViewTableViewCellDelegate: AnyObject {
    func collectionViewTableViewCellDidTap(cell: CollectionViewTableViewCell, viewModel: TitlePreviewViewModel)
}

class CollectionViewTableViewCell: UITableViewCell {

    static let identifier = "CollectionViewTableViewCell"

    weak var delegate: CollectionViewTableViewCellDelegate?

    private var titles: [Title] = [Title]()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 140, height: 200)
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TitleCollectionViewCell.self, forCellWithReuseIdentifier: TitleCollectionViewCell.identifier)
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .systemPink
        contentView.addSubview(collectionView)

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(with model: [Title]) {
        titles = model
        DispatchQueue.main.async {[weak self] in
            self?.collectionView.reloadData()
        }
    }

    private func downloadTitleAt(indexPath: IndexPath) {
        DataPersistenceManager.shared.downloadItemWith(model: titles[indexPath.row]) { result in
            switch result {
            case .success():
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloaded"), object: nil)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = contentView.bounds
    }
}

extension CollectionViewTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionViewCell.identifier, for: indexPath) as? TitleCollectionViewCell,
              let model = titles[indexPath.row].poster_path else {
            return UICollectionViewCell()
        }

        cell.configure(with: model)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let title = titles[indexPath.row]
        guard let titleName = title.original_name ?? title.original_title else {
            return
        }

        APICaller.shared.getMovie(with: "\(titleName) trailer".capitalizeFirstLetter()) { [weak self] result in
            switch result {
            case .success(let videoElement):
                let viewModel = TitlePreviewViewModel(
                    title: titleName,
                    youtubeVideo: videoElement,
                    titleOverview: title.overview ?? "Overview Unavailable"
                )

                guard let strongSelf = self else { return }
                self?.delegate?.collectionViewTableViewCellDidTap(cell: strongSelf, viewModel:viewModel)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil) { [weak self] _ in
                let downloadAction = UIAction(
                    title: "Download",
                    image: nil,
                    identifier: nil,
                    discoverabilityTitle: nil,
                    state: .off) { _ in
                        self?.downloadTitleAt(indexPath: indexPath)
                    }
                return UIMenu(
                    title: "",
                    image: nil,
                    identifier: nil,
                    options: .displayInline,
                    children: [downloadAction]
                )
            }
        return config
    }
}

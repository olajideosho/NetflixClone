//
//  DownloadsViewController.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 10/09/2022.
//

import UIKit

class DownloadsViewController: UIViewController {

    private var titles: [TitleItem] = [TitleItem]()

    private let downloadsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Downloads"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always

        view.addSubview(downloadsTableView)
        downloadsTableView.delegate = self
        downloadsTableView.dataSource = self

        fetchDownloadsFromLocalStorage()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "downloaded"), object: nil, queue: nil) { [weak self] _ in
            self?.fetchDownloadsFromLocalStorage()
            print("Refreshed")
        }
    }

    private func fetchDownloadsFromLocalStorage() {
        DataPersistenceManager.shared.fetchTitles {[weak self] result in
            switch result {
            case .success(let titles):
                self?.titles = titles
                DispatchQueue.main.async {
                    self?.downloadsTableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        downloadsTableView.frame = view.bounds
    }
}

extension DownloadsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }

        let title = titles[indexPath.row]
        cell.configure(
            with: TitleViewModel(
                titleName: title.original_name ?? title.original_title ?? "Unknown Title",
                posterURL: title.poster_path ?? ""
            )
        )

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            DataPersistenceManager.shared.deleteItemWith(model: titles[indexPath.row]) {[weak self] result in
                switch result {
                case .success():
                    self?.titles.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        default:
            break;
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let title = titles[indexPath.row]

        guard let titleName = title.original_name ?? title.original_title else {
            return
        }

        APICaller.shared.getMovie(with: "\(titleName) Trailer") { [weak self] result in
            switch result {
            case .success(let videoElement):
                DispatchQueue.main.async {
                    let vc = TitlePreviewViewController()
                    vc.configure(
                        with: TitlePreviewViewModel(
                            title: titleName,
                            youtubeVideo: videoElement,
                            titleOverview: title.overview ?? "Description Unavailable"
                        )
                    )
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

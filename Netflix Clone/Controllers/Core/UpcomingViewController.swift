//
//  UpcomingViewController.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 10/09/2022.
//

import UIKit

class UpcomingViewController: UIViewController {

    private var titles: [Title] = [Title]()

    private let upcomingTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Upcoming"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always

        view.addSubview(upcomingTableView)
        upcomingTableView.delegate = self
        upcomingTableView.dataSource = self

        fetchUpcoming()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        upcomingTableView.frame = view.bounds
    }

    private func fetchUpcoming() {
        APICaller.shared.getUpcomingMovies {[weak self] results in
            switch results {
            case .success(let titles):
                self?.titles = titles
                DispatchQueue.main.async {
                    self?.upcomingTableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension UpcomingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }

        let title = titles[indexPath.row]
        cell.configure(with: TitleViewModel(titleName: title.original_name ?? title.original_title ?? "Unknown Title Name", posterURL: title.poster_path ?? ""))

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
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

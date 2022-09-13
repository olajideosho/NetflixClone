//
//  SearchViewController.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 10/09/2022.
//

import UIKit

class SearchViewController: UIViewController {

    private var titles: [Title] = [Title]()

    private let discoverTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return tableView
    }()

    private let searchViewController: UISearchController = {
        let controller = UISearchController(searchResultsController: SearchResultsViewController())
        controller.searchBar.placeholder = "Search for a Movie or Tv show"
        controller.searchBar.searchBarStyle = .minimal
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .systemBackground

        view.addSubview(discoverTableView)
        discoverTableView.dataSource = self
        discoverTableView.delegate = self

        navigationItem.searchController = searchViewController
        navigationController?.navigationBar.tintColor = .white

        fetchDiscoverMovies()

        searchViewController.searchResultsUpdater = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        discoverTableView.frame = view.bounds
    }

    private func fetchDiscoverMovies() {
        APICaller.shared.getDiscoverMovies {[weak self] results in
            switch results {
            case .success(let titles):
                self?.titles = titles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.discoverTableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }

        let title = titles[indexPath.row]
        let model = TitleViewModel(titleName: title.original_name ?? title.original_title ?? "Unknown Title", posterURL: title.poster_path ?? "")
        cell.configure(with: model)
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

extension SearchViewController: UISearchResultsUpdating, SearchResultsViewControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar

        guard let query = searchBar.text,
              !query.trimmingCharacters(in: .whitespaces).isEmpty,
              query.trimmingCharacters(in: .whitespaces).count >= 3,
              let searchResultsController = searchController.searchResultsController as? SearchResultsViewController else {
            return
        }

        searchResultsController.delegate = self

        APICaller.shared.search(with: query) { results in
            switch results {
            case .success(let titles):
                DispatchQueue.main.async {
                    searchResultsController.updateSearchResults(with: titles)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    func searchResultsViewControllerDidTapItem(_ viewModel: TitlePreviewViewModel) {
        DispatchQueue.main.async {[weak self] in
            let vc = TitlePreviewViewController()
            vc.configure(with: viewModel)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//
//  HomeViewController.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 10/09/2022.
//

import UIKit

enum Sections: Int {
    case TrendingMovies = 0
    case TrendingTV = 1
    case Popular = 2
    case UpcomingMovies = 3
    case TopRated = 4
}

class HomeViewController: UIViewController {

    private let sectionTitles = ["Trending Movies", "Trending TV", "Popular", "Upcoming Movies", "Top Rated"]

    private var heroHeaderView: HeroHeaderUIView?

    private var randomTrendingMovie: Title?

    private let homeFeedTable: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(CollectionViewTableViewCell.self, forCellReuseIdentifier: CollectionViewTableViewCell.identifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(homeFeedTable)

        homeFeedTable.delegate = self
        homeFeedTable.dataSource = self

        configureNavbar()

        heroHeaderView = HeroHeaderUIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 450))
        homeFeedTable.tableHeaderView = heroHeaderView

        configureHeroHeaderView()
    }

    private func configureHeroHeaderView() {
        APICaller.shared.getTrendingMovies {[weak self] result in
            switch result {
            case .success(let titles):
                self?.randomTrendingMovie = titles.randomElement()
                self?.heroHeaderView?.configure(
                    with: TitleViewModel(
                        titleName: self?.randomTrendingMovie?.original_title ?? "",
                        posterURL: self?.randomTrendingMovie?.poster_path ?? ""
                    )
                )
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    private func configureNavbar() {
        var image = UIImage(named: "netflixLogo")
        image = image?.withRenderingMode(.alwaysOriginal)
        let leftBarButton = UIBarButtonItem(image: image, style: .done, target: self, action: nil)
        let leftDisplacement = (view.bounds.width / 5) - 20
        leftBarButton.imageInsets = UIEdgeInsets(top: 0, left: -leftDisplacement, bottom: 0, right: 0)
        navigationItem.leftBarButtonItem = leftBarButton

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "person"), style: .done, target: self, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "play.rectangle"), style: .done, target: self, action: nil)
        ]

        navigationController?.navigationBar.tintColor = .white
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeFeedTable.frame = view.bounds
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CollectionViewTableViewCell.identifier, for: indexPath) as? CollectionViewTableViewCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        switch indexPath.section {
        case Sections.TrendingMovies.rawValue:
            APICaller.shared.getTrendingMovies { results in
                switch results {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        case Sections.TrendingTV.rawValue:
            APICaller.shared.getTrendingTvs { results in
                switch results {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        case Sections.Popular.rawValue:
            APICaller.shared.getPopular { results in
                switch results {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        case Sections.UpcomingMovies.rawValue:
            APICaller.shared.getUpcomingMovies { results in
                switch results {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        case Sections.TopRated.rawValue:
            APICaller.shared.getTopRated { results in
                switch results {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
        default:
            return UITableViewCell()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }

        var contentConfiguration = header.defaultContentConfiguration()
        contentConfiguration.textProperties.color = .white
        contentConfiguration.text = sectionTitles[section].capitalizeFirstLetter()
        contentConfiguration.textProperties.transform = .none
        contentConfiguration.textProperties.font = .systemFont(ofSize: 18, weight: .semibold)

        header.contentConfiguration = contentConfiguration
        header.frame = CGRect(x: tableView.bounds.origin.x + 20, y: tableView.bounds.origin.y, width: 100, height: header.bounds.height)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section].capitalizeFirstLetter()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let defaultOffset = view.safeAreaInsets.top
        let offset = scrollView.contentOffset.y + defaultOffset

        navigationController?.navigationBar.transform = .init(translationX: 0, y: min(0, -offset))
    }
}

extension HomeViewController: CollectionViewTableViewCellDelegate {
    func collectionViewTableViewCellDidTap(cell: CollectionViewTableViewCell, viewModel: TitlePreviewViewModel) {
        DispatchQueue.main.async {[weak self] in
            let vc = TitlePreviewViewController()
            vc.configure(with: viewModel)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit // for Maps
import CoreLocation // to get User's location

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // =========================================================================
    // Outlets
    // =========================================================================
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    // =========================================================================
    // Properties
    // =========================================================================
    var businesses: [Business]!
    
    var filteredBusinesses: [Business]!
    
    var searchController: UISearchController!
    
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    var offset = 0
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up Infinite Scroll Loading Indicator
        // ---------------------------------------------------------------------
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        tableView.contentInset = insets
        // ---------------------------------------------------------------------
        
        // set up delegate and datasource for tableView
        tableView.delegate = self
        tableView.dataSource = self
        
        // set filteredBusinesses equal to businesses
        filteredBusinesses = businesses
        
        // give the tableView an estimate before it figures out the actual height
        tableView.estimatedRowHeight = 150
        // tell rowHeight to use AutoLayout Parameters
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Search Bar in Navigation View Code
        //-----------------------------------
        // create the search bar programatically since you can't
        // drag it onto the navigation bar
        
        // initializing searchController
        // searchResultsController set to nil, so it will use this VC to display results
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        // since we're using the same VC to present the results, it doesn't make sense
        // to dim it out.
        searchController.dimsBackgroundDuringPresentation = false
        
        // set searchBar size to Fit
        searchController.searchBar.sizeToFit()
        
        // set code so that searchController doesn't disappear
        searchController.hidesNavigationBarDuringPresentation = false
        
        // the UIViewController comes with a navigationItem property
        // this will automatically be initialized for you if/when the
        // view controller is added to a navigation controller's stack
        // you just need to set the titleView to be the search bar
        
        navigationItem.titleView = searchController.searchBar
        //-----------------------------------
        
        Business.searchWithTerm(term: "Thai", offset: offset, completion: { (businesses: [Business]?, error: Error?) -> Void in
            
            self.businesses = businesses
            self.filteredBusinesses = businesses
            
            self.offset += 20
            
            if let businesses = businesses {
                for business in businesses {
                    print(business.name!)
                    print(business.address!)
                    
                    self.addAnnotationAt(address: business.address!, title: business.name!)
                }
            }
            
            // update tableView
            self.tableView.reloadData()
        })
        
        /* Example of Yelp search with more search options specified
         Business.searchWithTerm("Restaurants", sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
         self.businesses = businesses
         
         for business in businesses {
         print(business.name!)
         print(business.address!)
         }
         }
         */
        
        setupMaps()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // set number of rows in a particular section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filteredBusinesses != nil {
            return filteredBusinesses.count
        }
        
        return 0
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Business Cell", for: indexPath) as! BusinessCell
        
        cell.business = filteredBusinesses[indexPath.row]
        
        return cell
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension BusinessesViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filteredBusinesses = searchText.isEmpty ? businesses : businesses.filter({(data: Business) -> Bool in
                return data.name?.range(of: searchText, options: .caseInsensitive) != nil
            })
            
            // reload the data in the table view
            tableView.reloadData()
        }
    }

}

extension BusinessesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // handle scroll behavior here
        
        // if more data isn't already loading
        if (!isMoreDataLoading) {
            // calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // when the user has scrolled past the threshold, start requesting
            if (scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
                
                isMoreDataLoading = true
                
                // update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // code to load more results
                Business.searchWithTerm(term: "Thai", offset: offset, completion:  {
                    (businesses: [Business]?, error: Error?) -> Void in
                    
                    // initialize the filtered data
                    if let businesses = businesses {
                        self.businesses.append(contentsOf: businesses)
                        self.filteredBusinesses = self.businesses
                    }
                    
                    // update offset
                    self.offset += 20
                    
                    // update flag
                    self.isMoreDataLoading = false
                    
                    // stop the loading indicator
                    self.loadingMoreView!.stopAnimating()
                    
                    // update tableView
                    self.tableView.reloadData()
                    
                    if let businesses = businesses {
                        for business in businesses {
                            print(business.name!)
                            print(business.address!)
                        }
                    }
                    
                })
            }
            
        }
    }
    
}

extension BusinessesViewController: CLLocationManagerDelegate {
    
    func setupMaps() {
        // set the region to display, this also sets a correct zoom level
        // set starting center location in San Francisco
        let centerLocation = CLLocation(latitude: 37.785771, longitude: -122.406165)
        goToLocation(centerLocation)
        
        // get User's location
        // ---------------------------------------------------------------------
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization() // request location access
        // ---------------------------------------------------------------------
    }
    
    func goToLocation(_ location: CLLocation) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Helper Functions for Creating Annotations
    // -------------------------------------------------------------------------
    // add an Annotation with a coordinate: CLLocationCoordinate2D
    func addAnnotationAt(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "An annotation!"
        mapView.addAnnotation(annotation)
    }
    
    // add an Annotation with an address: String
    func addAnnotationAt(address: String, title: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let placemarks = placemarks {
                if placemarks.count != 0 {
                    let coordinate = placemarks.first!.location!
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate.coordinate
                    annotation.title = title
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    // -------------------------------------------------------------------------
    
}
